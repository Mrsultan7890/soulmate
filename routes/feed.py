from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from typing import List, Optional
import json
from datetime import datetime, timedelta
from config.database import get_db
from routes.auth import get_current_user
from services.telegram_service import get_image_url

router = APIRouter(prefix="/api/feed", tags=["feed"])

class FeedPost(BaseModel):
    id: int
    user_id: int
    image_url: str
    likes_count: int
    is_liked: bool
    is_favorited: bool
    user_age: Optional[int]
    user_location: Optional[str]
    created_at: str

@router.get("/posts", response_model=List[FeedPost])
async def get_feed_posts(
    page: int = 1,
    limit: int = 20,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Get feed posts with user photos"""
    offset = (page - 1) * limit
    
    # Get posts from users who have feed visibility enabled
    posts = await db.fetchall("""
        SELECT 
            fp.id,
            fp.user_id,
            fp.image_file_id,
            fp.likes_count,
            fp.created_at,
            u.age,
            u.location,
            CASE WHEN fl.id IS NOT NULL THEN 1 ELSE 0 END as is_liked,
            CASE WHEN ff.id IS NOT NULL THEN 1 ELSE 0 END as is_favorited
        FROM feed_posts fp
        JOIN users u ON fp.user_id = u.id
        JOIN user_settings us ON u.id = us.user_id
        LEFT JOIN feed_likes fl ON fp.id = fl.post_id AND fl.user_id = ?
        LEFT JOIN feed_favorites ff ON fp.id = ff.post_id AND ff.user_id = ?
        WHERE fp.is_active = 1 
        AND us.show_in_feed = 1 
        AND fp.user_id != ?
        ORDER BY fp.created_at DESC
        LIMIT ? OFFSET ?
    """, (current_user["id"], current_user["id"], current_user["id"], limit, offset))
    
    feed_posts = []
    for post in posts:
        image_url = await get_image_url(post["image_file_id"])
        feed_posts.append(FeedPost(
            id=post["id"],
            user_id=post["user_id"],
            image_url=image_url,
            likes_count=post["likes_count"],
            is_liked=bool(post["is_liked"]),
            is_favorited=bool(post["is_favorited"]),
            user_age=post["age"],
            user_location=post["location"],
            created_at=post["created_at"]
        ))
    
    return feed_posts

@router.post("/posts/{post_id}/like")
async def like_post(
    post_id: int,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Like/unlike a feed post"""
    # Check if already liked
    existing_like = await db.fetchone("""
        SELECT id FROM feed_likes WHERE post_id = ? AND user_id = ?
    """, (post_id, current_user["id"]))
    
    if existing_like:
        # Unlike
        await db.execute("""
            DELETE FROM feed_likes WHERE post_id = ? AND user_id = ?
        """, (post_id, current_user["id"]))
        
        await db.execute("""
            UPDATE feed_posts SET likes_count = likes_count - 1 WHERE id = ?
        """, (post_id,))
        
        await db.commit()
        return {"liked": False, "message": "Post unliked"}
    else:
        # Like
        await db.execute("""
            INSERT INTO feed_likes (post_id, user_id) VALUES (?, ?)
        """, (post_id, current_user["id"]))
        
        await db.execute("""
            UPDATE feed_posts SET likes_count = likes_count + 1 WHERE id = ?
        """, (post_id,))
        
        await db.commit()
        return {"liked": True, "message": "Post liked"}

@router.post("/posts/{post_id}/favorite")
async def favorite_post(
    post_id: int,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Add/remove post from favorites"""
    existing_fav = await db.fetchone("""
        SELECT id FROM feed_favorites WHERE post_id = ? AND user_id = ?
    """, (post_id, current_user["id"]))
    
    if existing_fav:
        # Remove from favorites
        await db.execute("""
            DELETE FROM feed_favorites WHERE post_id = ? AND user_id = ?
        """, (post_id, current_user["id"]))
        await db.commit()
        return {"favorited": False, "message": "Removed from favorites"}
    else:
        # Add to favorites
        await db.execute("""
            INSERT INTO feed_favorites (post_id, user_id) VALUES (?, ?)
        """, (post_id, current_user["id"]))
        await db.commit()
        return {"favorited": True, "message": "Added to favorites"}

@router.get("/favorites", response_model=List[FeedPost])
async def get_favorites(
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Get user's favorite posts"""
    posts = await db.fetchall("""
        SELECT 
            fp.id,
            fp.user_id,
            fp.image_file_id,
            fp.likes_count,
            fp.created_at,
            u.age,
            u.location,
            1 as is_liked,
            1 as is_favorited
        FROM feed_favorites ff
        JOIN feed_posts fp ON ff.post_id = fp.id
        JOIN users u ON fp.user_id = u.id
        WHERE ff.user_id = ? AND fp.is_active = 1
        ORDER BY ff.created_at DESC
    """, (current_user["id"],))
    
    favorites = []
    for post in posts:
        image_url = await get_image_url(post["image_file_id"])
        favorites.append(FeedPost(
            id=post["id"],
            user_id=post["user_id"],
            image_url=image_url,
            likes_count=post["likes_count"],
            is_liked=True,
            is_favorited=True,
            user_age=post["age"],
            user_location=post["location"],
            created_at=post["created_at"]
        ))
    
    return favorites

@router.get("/posts/{post_id}/user")
async def get_post_user_profile(
    post_id: int,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Get user profile from feed post"""
    post = await db.fetchone("""
        SELECT user_id FROM feed_posts WHERE id = ?
    """, (post_id,))
    
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")
    
    # Get user profile
    user = await db.fetchone("""
        SELECT id, name, age, bio, location, profile_images, interests
        FROM users WHERE id = ?
    """, (post["user_id"],))
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    # Get profile images
    profile_images = []
    if user["profile_images"]:
        image_ids = json.loads(user["profile_images"])
        for img_id in image_ids:
            url = await get_image_url(img_id)
            profile_images.append(url)
    
    return {
        "id": user["id"],
        "name": user["name"],
        "age": user["age"],
        "bio": user["bio"],
        "location": user["location"],
        "profile_images": profile_images,
        "interests": json.loads(user["interests"]) if user["interests"] else []
    }

@router.post("/refresh-posts")
async def refresh_user_posts(
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Refresh user's posts in feed from their profile images"""
    # Get user's profile images
    user = await db.fetchone("""
        SELECT profile_images FROM users WHERE id = ?
    """, (current_user["id"],))
    
    if not user or not user["profile_images"]:
        return {"message": "No profile images found"}
    
    # Clear existing posts
    await db.execute("""
        UPDATE feed_posts SET is_active = 0 WHERE user_id = ?
    """, (current_user["id"],))
    
    # Add new posts from profile images
    image_ids = json.loads(user["profile_images"])
    for img_id in image_ids:
        await db.execute("""
            INSERT INTO feed_posts (user_id, image_file_id) VALUES (?, ?)
        """, (current_user["id"], img_id))
    
    await db.commit()
    return {"message": f"Added {len(image_ids)} posts to feed"}
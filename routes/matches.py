from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
import json

from models.schemas import SwipeCreate, SwipeResponse, Match, UserProfile
from routes.auth import get_current_user
from config.database import get_db
from services.notification_service import send_match_notification

router = APIRouter()

@router.post("/swipe", response_model=SwipeResponse)
async def swipe_user(
    swipe: SwipeCreate,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Swipe on a user (like or pass)"""
    try:
        # Check if already swiped
        existing = await db.fetchone(
            "SELECT * FROM swipes WHERE swiper_id = ? AND swiped_id = ?",
            (current_user["id"], swipe.swiped_user_id)
        )
        
        if existing:
            return SwipeResponse(is_match=False, match_id=None)
        
        # Store swipe
        await db.execute(
            "INSERT INTO swipes (swiper_id, swiped_id, is_like) VALUES (?, ?, ?)",
            (current_user["id"], swipe.swiped_user_id, swipe.is_like)
        )
        await db.commit()
        
        # Check for mutual like (match)
        is_match = False
        match_id = None
        
        if swipe.is_like:
            mutual_like = await db.fetchone(
                "SELECT * FROM swipes WHERE swiper_id = ? AND swiped_id = ? AND is_like = 1",
                (swipe.swiped_user_id, current_user["id"])
            )
            
            if mutual_like:
                # Check if match already exists
                existing_match = await db.fetchone(
                    "SELECT * FROM matches WHERE (user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?)",
                    (current_user["id"], swipe.swiped_user_id, swipe.swiped_user_id, current_user["id"])
                )
                
                if not existing_match:
                    # Create match
                    cursor = await db.execute(
                        "INSERT INTO matches (user1_id, user2_id) VALUES (?, ?)",
                        (current_user["id"], swipe.swiped_user_id)
                    )
                    match_id = cursor.lastrowid
                    await db.commit()
                    is_match = True
                    
                    # Send notification service alert
                    await send_match_notification(current_user["id"], swipe.swiped_user_id)
                    
                    # Send FCM notification
                    from services.fcm_notification_service import fcm_service
                    other_user = await db.fetchone("SELECT fcm_token, name FROM users WHERE id = ?", (swipe.swiped_user_id,))
                    print(f"\n=== MATCH NOTIFICATION ===")
                    print(f"Other user: {other_user}")
                    if other_user and other_user['fcm_token']:
                        print(f"Sending FCM to token: {other_user['fcm_token'][:20]}...")
                        result = await fcm_service.send_match_notification(
                            fcm_token=other_user['fcm_token'],
                            matched_user_name=current_user['name']
                        )
                        print(f"FCM result: {result}")
                    else:
                        print(f"No FCM token for user {swipe.swiped_user_id}")
                    print(f"=== END MATCH NOTIFICATION ===")
                else:
                    match_id = existing_match['id']
                    is_match = True
        
        return SwipeResponse(is_match=is_match, match_id=match_id)
        
    except Exception as e:
        print(f"Swipe error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to process swipe: {str(e)}"
        )

@router.get("/")
async def get_matches(
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Get all matches for current user"""
    try:
        from services.telegram_service import get_image_url
        
        matches = await db.fetchall("""
            SELECT 
                m.*,
                u1.id as user1_id, u1.name as user1_name, u1.age as user1_age,
                u1.bio as user1_bio, u1.profile_images as user1_images,
                u2.id as user2_id, u2.name as user2_name, u2.age as user2_age,
                u2.bio as user2_bio, u2.profile_images as user2_images
            FROM matches m
            JOIN users u1 ON m.user1_id = u1.id
            JOIN users u2 ON m.user2_id = u2.id
            WHERE m.user1_id = ? OR m.user2_id = ?
            ORDER BY m.created_at DESC
        """, (current_user["id"], current_user["id"]))
        
        match_list = []
        for match in matches:
            match_dict = dict(match)
            
            if match_dict["user1_id"] == current_user["id"]:
                other_user_data = {
                    "id": match_dict["user2_id"],
                    "name": match_dict["user2_name"],
                    "age": match_dict["user2_age"],
                    "bio": match_dict["user2_bio"],
                    "profile_images": match_dict["user2_images"]
                }
            else:
                other_user_data = {
                    "id": match_dict["user1_id"],
                    "name": match_dict["user1_name"],
                    "age": match_dict["user1_age"],
                    "bio": match_dict["user1_bio"],
                    "profile_images": match_dict["user1_images"]
                }
            
            profile_images = json.loads(other_user_data["profile_images"])
            image_urls = []
            for file_id in profile_images[:1]:
                try:
                    url = await get_image_url(file_id)
                    image_urls.append(url)
                except:
                    image_urls.append("https://via.placeholder.com/400x400/FF6B6B/FFFFFF?text=HeartLink")
            
            if not image_urls:
                image_urls = ["https://via.placeholder.com/400x400/FF6B6B/FFFFFF?text=HeartLink"]
            
            match_data = {
                "id": match_dict["id"],
                "other_user": {
                    "id": other_user_data["id"],
                    "name": other_user_data["name"],
                    "age": other_user_data["age"],
                    "bio": other_user_data["bio"],
                    "profile_images": image_urls
                },
                "created_at": match_dict["created_at"]
            }
            
            match_list.append(match_data)
        
        return match_list
        
    except Exception as e:
        print(f"Get matches error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch matches: {str(e)}"
        )

@router.delete("/{match_id}")
async def unmatch_user(
    match_id: int,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Unmatch with a user"""
    try:
        # Verify match belongs to current user
        match = await db.fetchone(
            "SELECT * FROM matches WHERE id = ? AND (user1_id = ? OR user2_id = ?)",
            (match_id, current_user["id"], current_user["id"])
        )
        
        if not match:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Match not found"
            )
        
        # Delete match and related messages
        await db.execute("DELETE FROM messages WHERE match_id = ?", (match_id,))
        await db.execute("DELETE FROM matches WHERE id = ?", (match_id,))
        await db.commit()
        
        return {"message": "Successfully unmatched"}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to unmatch: {str(e)}"
        )
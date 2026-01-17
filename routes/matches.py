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
        print(f"\n=== SWIPE REQUEST ===")
        print(f"Swiper: {current_user['id']}")
        print(f"Swiped: {swipe.swiped_user_id}")
        print(f"Is Like: {swipe.is_like}")
        
        # Check if already swiped (including undone)
        existing = await db.fetchone(
            "SELECT * FROM swipes WHERE swiper_id = ? AND swiped_id = ?",
            (current_user["id"], swipe.swiped_user_id)
        )
        
        if existing:
            print(f"Already swiped: {dict(existing)}")
            # If undone, update the existing swipe
            if existing['is_undone'] == 1:
                await db.execute(
                    "UPDATE swipes SET is_like = ?, is_undone = 0, created_at = CURRENT_TIMESTAMP WHERE id = ?",
                    (swipe.is_like, existing['id'])
                )
                await db.commit()
                print(f"Updated existing undone swipe")
            else:
                return SwipeResponse(is_match=False, match_id=None)
        else:
            # Store new swipe
            await db.execute(
                "INSERT INTO swipes (swiper_id, swiped_id, is_like) VALUES (?, ?, ?)",
                (current_user["id"], swipe.swiped_user_id, swipe.is_like)
            )
            await db.commit()
            print(f"New swipe saved successfully")
        
        # Check for mutual like (match)
        is_match = False
        match_id = None
        
        if swipe.is_like:
            mutual_like = await db.fetchone(
                "SELECT * FROM swipes WHERE swiper_id = ? AND swiped_id = ? AND is_like = 1 AND (is_undone = 0 OR is_undone IS NULL)",
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
        
        print(f"Final result - Match: {is_match}, Match ID: {match_id}")
        print(f"=== END SWIPE ===")
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

@router.post("/undo-swipe")
async def undo_last_swipe(
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Undo the last swipe"""
    try:
        print(f"\n=== UNDO SWIPE REQUEST ===")
        print(f"User ID: {current_user['id']}")
        
        # Get last swipe (not undone) - fix column names
        last_swipe = await db.fetchone(
            "SELECT * FROM swipes WHERE swiper_id = ? AND (is_undone = 0 OR is_undone IS NULL) ORDER BY created_at DESC LIMIT 1",
            (current_user["id"],)
        )
        
        # Also check all swipes for debugging
        all_swipes = await db.fetchall(
            "SELECT * FROM swipes WHERE swiper_id = ? ORDER BY created_at DESC LIMIT 3",
            (current_user["id"],)
        )
        print(f"All recent swipes: {[dict(s) for s in all_swipes]}")
        
        print(f"Last swipe found: {dict(last_swipe) if last_swipe else 'None'}")
        
        if not last_swipe:
            print("No swipe to undo")
            raise HTTPException(status_code=404, detail="No swipe to undo")
        
        # Mark as undone
        await db.execute(
            "UPDATE swipes SET is_undone = 1 WHERE id = ?",
            (last_swipe["id"],)
        )
        await db.commit()
        
        print(f"Swipe {last_swipe['id']} marked as undone")
        print(f"=== END UNDO SWIPE ===")
        
        return {
            "success": True,
            "message": "Swipe undone",
            "swiped_user_id": last_swipe["swiped_id"]
        }
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Undo swipe error: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/who-liked-me")
async def who_liked_me(
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Get users who liked you"""
    try:
        from services.telegram_service import get_image_url
        
        # Get users who liked current user (but current user hasn't swiped yet)
        likes = await db.fetchall("""
            SELECT u.id, u.name, u.age, u.bio, u.profile_images, s.created_at as liked_at
            FROM swipes s
            JOIN users u ON s.swiper_id = u.id
            WHERE s.swiped_id = ? AND s.is_like = 1 AND s.is_undone = 0
            AND NOT EXISTS (
                SELECT 1 FROM swipes s2 
                WHERE s2.swiper_id = ? AND s2.swiped_id = u.id
            )
            ORDER BY s.created_at DESC
        """, (current_user["id"], current_user["id"]))
        
        users_list = []
        for user in likes:
            user_dict = dict(user)
            profile_images = json.loads(user_dict.get("profile_images", "[]"))
            image_urls = []
            
            if profile_images:
                for file_id in profile_images[:1]:
                    try:
                        url = await get_image_url(file_id)
                        image_urls.append(url)
                    except:
                        image_urls.append("https://via.placeholder.com/400x400/FF6B6B/FFFFFF?text=HeartLink")
            else:
                image_urls.append("https://via.placeholder.com/400x400/FF6B6B/FFFFFF?text=HeartLink")
            
            users_list.append({
                "id": user_dict["id"],
                "name": user_dict["name"],
                "age": user_dict["age"],
                "bio": user_dict["bio"],
                "profile_images": image_urls,
                "liked_at": user_dict["liked_at"]
            })
        
        return {
            "count": len(users_list),
            "users": users_list
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
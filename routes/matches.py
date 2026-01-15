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
        existing_swipe = await db.fetchone(
            "SELECT id FROM swipes WHERE swiper_id = ? AND swiped_id = ?",
            (current_user["id"], swipe.swiped_user_id)
        )
        
        if existing_swipe:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Already swiped on this user"
            )
        
        # Record the swipe
        await db.execute(
            "INSERT INTO swipes (swiper_id, swiped_id, is_like) VALUES (?, ?, ?)",
            (current_user["id"], swipe.swiped_user_id, swipe.is_like)
        )
        
        is_match = False
        match_id = None
        
        # Check for mutual like (match)
        if swipe.is_like:
            mutual_like = await db.fetchone(
                "SELECT id FROM swipes WHERE swiper_id = ? AND swiped_id = ? AND is_like = TRUE",
                (swipe.swiped_user_id, current_user["id"])
            )
            
            if mutual_like:
                # Create match
                await db.execute(
                    "INSERT INTO matches (user1_id, user2_id) VALUES (?, ?)",
                    (min(current_user["id"], swipe.swiped_user_id), 
                     max(current_user["id"], swipe.swiped_user_id))
                )
                
                # Get match ID
                match = await db.fetchone(
                    "SELECT id FROM matches WHERE user1_id = ? AND user2_id = ?",
                    (min(current_user["id"], swipe.swiped_user_id),
                     max(current_user["id"], swipe.swiped_user_id))
                )
                
                is_match = True
                match_id = match["id"]
                
                # Send match notification
                await send_match_notification(current_user["id"], swipe.swiped_user_id)
        
        await db.commit()
        
        return SwipeResponse(is_match=is_match, match_id=match_id)
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to process swipe: {str(e)}"
        )

@router.get("/", response_model=List[Match])
async def get_matches(
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Get all matches for current user"""
    try:
        matches = await db.fetchall("""
            SELECT 
                m.*,
                u1.id as user1_id, u1.name as user1_name, u1.age as user1_age,
                u1.bio as user1_bio, u1.profile_images as user1_images,
                u2.id as user2_id, u2.name as user2_name, u2.age as user2_age,
                u2.bio as user2_bio, u2.profile_images as user2_images,
                msg.content as last_message,
                msg.created_at as last_message_time
            FROM matches m
            JOIN users u1 ON m.user1_id = u1.id
            JOIN users u2 ON m.user2_id = u2.id
            LEFT JOIN (
                SELECT match_id, content, created_at,
                       ROW_NUMBER() OVER (PARTITION BY match_id ORDER BY created_at DESC) as rn
                FROM messages
            ) msg ON m.id = msg.match_id AND msg.rn = 1
            WHERE m.user1_id = ? OR m.user2_id = ?
            ORDER BY COALESCE(msg.created_at, m.created_at) DESC
        """, (current_user["id"], current_user["id"]))
        
        match_list = []
        for match in matches:
            match_dict = dict(match)
            
            # Determine which user is the other user
            if match_dict["user1_id"] == current_user["id"]:
                other_user = {
                    "id": match_dict["user2_id"],
                    "name": match_dict["user2_name"],
                    "age": match_dict["user2_age"],
                    "bio": match_dict["user2_bio"],
                    "profile_images": json.loads(match_dict["user2_images"])
                }
            else:
                other_user = {
                    "id": match_dict["user1_id"],
                    "name": match_dict["user1_name"],
                    "age": match_dict["user1_age"],
                    "bio": match_dict["user1_bio"],
                    "profile_images": json.loads(match_dict["user1_images"])
                }
            
            # Create user profiles
            user1_profile = UserProfile(
                id=match_dict["user1_id"],
                email="",  # Don't expose email
                name=match_dict["user1_name"],
                age=match_dict["user1_age"],
                bio=match_dict["user1_bio"],
                profile_images=json.loads(match_dict["user1_images"]),
                preferences={},
                is_verified=False,
                is_premium=False,
                created_at=match_dict["created_at"]
            )
            
            user2_profile = UserProfile(
                id=match_dict["user2_id"],
                email="",  # Don't expose email
                name=match_dict["user2_name"],
                age=match_dict["user2_age"],
                bio=match_dict["user2_bio"],
                profile_images=json.loads(match_dict["user2_images"]),
                preferences={},
                is_verified=False,
                is_premium=False,
                created_at=match_dict["created_at"]
            )
            
            match_list.append(Match(
                id=match_dict["id"],
                user1_id=match_dict["user1_id"],
                user2_id=match_dict["user2_id"],
                user1_profile=user1_profile,
                user2_profile=user2_profile,
                created_at=match_dict["created_at"],
                last_message=match_dict["last_message"],
                last_message_time=match_dict["last_message_time"]
            ))
        
        return match_list
        
    except Exception as e:
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
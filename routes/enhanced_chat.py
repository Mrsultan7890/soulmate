from fastapi import APIRouter, Depends, HTTPException, status
from typing import Dict, List
import json
from datetime import datetime

from routes.auth import get_current_user
from config.database import get_db
from services.anti_scam_service import AntiScamService

router = APIRouter()

@router.post("/send-message")
async def send_message(
    message_data: dict,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Send message with enhanced features"""
    try:
        match_id = message_data.get('match_id')
        content = message_data.get('content', '').strip()
        message_type = message_data.get('message_type', 'text')
        
        if not match_id or not content:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Match ID and content are required"
            )
        
        # Verify match exists
        match = await db.fetchone("""
            SELECT * FROM matches 
            WHERE id = ? AND (user1_id = ? OR user2_id = ?)
        """, (match_id, current_user["id"], current_user["id"]))
        
        if not match:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Match not found"
            )
        
        # Insert message
        cursor = await db.execute("""
            INSERT INTO messages (match_id, sender_id, content, message_type)
            VALUES (?, ?, ?, ?)
        """, (match_id, current_user["id"], content, message_type))
        
        message_id = cursor.lastrowid
        await db.commit()
        
        return {
            "message_id": message_id,
            "status": "sent"
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to send message: {str(e)}"
        )

@router.delete("/message/{message_id}")
async def delete_message(
    message_id: int,
    for_everyone: bool = False,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Delete message"""
    try:
        message = await db.fetchone(
            "SELECT * FROM messages WHERE id = ?",
            (message_id,)
        )
        
        if not message:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Message not found"
            )
        
        if message['sender_id'] != current_user["id"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Can only delete your own messages"
            )
        
        if for_everyone:
            await db.execute("DELETE FROM messages WHERE id = ?", (message_id,))
        else:
            # Mark as deleted for current user only
            await db.execute(
                "UPDATE messages SET deleted_for = ? WHERE id = ?",
                (current_user["id"], message_id)
            )
        
        await db.commit()
        
        return {"message": "Message deleted"}
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete message: {str(e)}"
        )

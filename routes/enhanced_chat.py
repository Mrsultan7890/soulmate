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

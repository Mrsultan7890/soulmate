from fastapi import APIRouter, Depends, HTTPException, status, WebSocket, WebSocketDisconnect
from typing import List
import json
from datetime import datetime

from models.schemas import MessageCreate, Message
from routes.auth import get_current_user
from config.database import get_db
from services.websocket_manager import manager
from services.anti_scam_service import AntiScamService
from services.notification_service import send_message_notification

router = APIRouter()

@router.get("/{match_id}/messages", response_model=List[Message])
async def get_messages(
    match_id: int,
    limit: int = 50,
    offset: int = 0,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Get messages for a match"""
    try:
        # Verify user is part of this match
        match = await db.fetchone(
            "SELECT * FROM matches WHERE id = ? AND (user1_id = ? OR user2_id = ?)",
            (match_id, current_user["id"], current_user["id"])
        )
        
        if not match:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Match not found"
            )
        
        # Get messages
        messages = await db.fetchall("""
            SELECT m.*, u.name as sender_name
            FROM messages m
            JOIN users u ON m.sender_id = u.id
            WHERE m.match_id = ?
            ORDER BY m.created_at DESC
            LIMIT ? OFFSET ?
        """, (match_id, limit, offset))
        
        message_list = []
        for msg in messages:
            msg_dict = dict(msg)
            message_list.append(Message(
                id=msg_dict["id"],
                match_id=msg_dict["match_id"],
                sender_id=msg_dict["sender_id"],
                content=msg_dict["content"],
                message_type=msg_dict["message_type"],
                is_read=msg_dict["is_read"],
                created_at=msg_dict["created_at"],
                sender_name=msg_dict["sender_name"]
            ))
        
        # Mark messages as read
        await db.execute(
            "UPDATE messages SET is_read = TRUE, read_at = CURRENT_TIMESTAMP WHERE match_id = ? AND sender_id != ?",
            (match_id, current_user["id"])
        )
        await db.commit()
        
        return list(reversed(message_list))  # Return in chronological order
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch messages: {str(e)}"
        )

@router.post("/{match_id}/messages", response_model=Message)
async def send_message(
    match_id: int,
    message: MessageCreate,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Send a message in a match"""
    try:
        # Verify user is part of this match
        match = await db.fetchone(
            "SELECT * FROM matches WHERE id = ? AND (user1_id = ? OR user2_id = ?)",
            (match_id, current_user["id"], current_user["id"])
        )
        
        if not match:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Match not found"
            )
        
        # Anti-scam check for phone numbers and social media
        content = message.content.lower()
        blocked_patterns = [
            # Phone patterns
            r'\b\d{10}\b',  # 10 digit numbers
            r'\b\d{3}[-.]\d{3}[-.]\d{4}\b',  # xxx-xxx-xxxx
            r'\+\d{1,3}\s?\d{10}',  # +91 xxxxxxxxxx
            # Social media
            'instagram', 'insta', 'ig:', '@',
            'whatsapp', 'telegram', 'snapchat',
            'facebook', 'twitter', 'tiktok'
        ]
        
        import re
        for pattern in blocked_patterns:
            if re.search(pattern, content):
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Messages containing phone numbers or social media handles are not allowed for safety reasons."
                )
        
        # Insert message
        await db.execute("""
            INSERT INTO messages (match_id, sender_id, content, message_type)
            VALUES (?, ?, ?, ?)
        """, (
            match_id, 
            current_user["id"], 
            message.content, 
            message.message_type
        ))
        
        # Get the created message
        created_message = await db.fetchone("""
            SELECT m.*, u.name as sender_name
            FROM messages m
            JOIN users u ON m.sender_id = u.id
            WHERE m.match_id = ? AND m.sender_id = ?
            ORDER BY m.created_at DESC
            LIMIT 1
        """, (match_id, current_user["id"]))
        
        await db.commit()
        
        msg_dict = dict(created_message)
        new_message = Message(
            id=msg_dict["id"],
            match_id=msg_dict["match_id"],
            sender_id=msg_dict["sender_id"],
            content=msg_dict["content"],
            message_type=msg_dict["message_type"],
            is_read=msg_dict["is_read"],
            created_at=msg_dict["created_at"],
            sender_name=msg_dict["sender_name"]
        )
        
        # Send WebSocket notification to receiver
        receiver_id = match["user1_id"] if match["user2_id"] == current_user["id"] else match["user2_id"]
        
        # Send Firebase push notification
        try:
            from services.fcm_notification_service import fcm_service
            receiver = await db.fetchone("SELECT fcm_token, name FROM users WHERE id = ?", (receiver_id,))
            print(f"\n=== MESSAGE NOTIFICATION ===")
            print(f"Receiver ID: {receiver_id}")
            print(f"Receiver data: {dict(receiver) if receiver else 'None'}")
            if receiver and receiver['fcm_token']:
                print(f"FCM token found: {receiver['fcm_token'][:20]}...")
                result = await fcm_service.send_message_notification(
                    fcm_token=receiver['fcm_token'],
                    sender_name=current_user['name'],
                    message_content=message.content
                )
                print(f"FCM result: {result}")
            else:
                print(f"❌ No FCM token for user {receiver_id}")
                if receiver:
                    print(f"User exists but fcm_token is: {receiver.get('fcm_token', 'NULL')}")
                else:
                    print(f"User {receiver_id} not found in database")
            print(f"=== END MESSAGE NOTIFICATION ===")
        except Exception as e:
            print(f"FCM notification error: {e}")
            import traceback
            traceback.print_exc()
        
        # Send real-time notification via WebSocket
        await manager.send_message_to_user(receiver_id, {
            "type": "new_message",
            "message": {
                "id": msg_dict["id"],
                "match_id": msg_dict["match_id"],
                "sender_id": msg_dict["sender_id"],
                "content": msg_dict["content"],
                "sender_name": msg_dict["sender_name"],
                "created_at": msg_dict["created_at"]
            }
        })
        
        # Send notification service alert
        await send_message_notification(current_user["id"], receiver_id, message.content)
        
        return new_message
        
    except HTTPException:
        raise
    except Exception as e:
        print(f"Send message error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to send message: {str(e)}"
        )

@router.websocket("/ws/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: int):
    """WebSocket endpoint for real-time chat"""
    await manager.connect(websocket, user_id)
    try:
        while True:
            data = await websocket.receive_text()
            message_data = json.loads(data)
            
            # Handle different message types
            if message_data.get("type") == "ping":
                await websocket.send_text(json.dumps({"type": "pong"}))
            elif message_data.get("type") == "typing":
                # Broadcast typing indicator to match partner
                match_id = message_data.get("match_id")
                if match_id:
                    await manager.broadcast_to_match(match_id, user_id, {
                        "type": "typing",
                        "user_id": user_id,
                        "is_typing": message_data.get("is_typing", False)
                    })
                    
    except WebSocketDisconnect:
        manager.disconnect(user_id)

@router.get("/{match_id}/unread-count")
async def get_unread_count(
    match_id: int,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Get unread message count for a match"""
    try:
        # Verify user is part of this match
        match = await db.fetchone(
            "SELECT * FROM matches WHERE id = ? AND (user1_id = ? OR user2_id = ?)",
            (match_id, current_user["id"], current_user["id"])
        )
        
        if not match:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Match not found"
            )
        
        # Count unread messages
        unread_count = await db.fetchone(
            "SELECT COUNT(*) as count FROM messages WHERE match_id = ? AND sender_id != ? AND is_read = FALSE",
            (match_id, current_user["id"])
        )
        
        return {"unread_count": unread_count["count"]}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get unread count: {str(e)}"
        )
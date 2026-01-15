import asyncio
from services.telegram_service import telegram_service
from config.database import get_db

async def send_match_notification(user1_id: int, user2_id: int):
    """Send match notification to both users"""
    try:
        db = await get_db()
        
        # Get user details
        user1 = await db.fetchone("SELECT name FROM users WHERE id = ?", (user1_id,))
        user2 = await db.fetchone("SELECT name FROM users WHERE id = ?", (user2_id,))
        
        if user1 and user2:
            # Send notification via Telegram (if configured)
            notification_text = f"🎉 New Match! {user1['name']} and {user2['name']} matched!"
            
            # You can extend this to send push notifications, emails, etc.
            print(f"Match notification: {notification_text}")
            
            # If you want to send to a Telegram channel/group
            # await telegram_service.send_message(notification_text)
            
    except Exception as e:
        print(f"Error sending match notification: {e}")

async def send_message_notification(sender_id: int, receiver_id: int, message_content: str):
    """Send new message notification"""
    try:
        db = await get_db()
        
        # Get sender details
        sender = await db.fetchone("SELECT name FROM users WHERE id = ?", (sender_id,))
        
        if sender:
            notification_text = f"💬 New message from {sender['name']}: {message_content[:50]}..."
            print(f"Message notification: {notification_text}")
            
            # Here you would implement push notifications to the receiver
            # For now, we'll just log it
            
    except Exception as e:
        print(f"Error sending message notification: {e}")

async def send_like_notification(liker_id: int, liked_id: int):
    """Send like notification"""
    try:
        db = await get_db()
        
        # Get liker details
        liker = await db.fetchone("SELECT name FROM users WHERE id = ?", (liker_id,))
        
        if liker:
            notification_text = f"❤️ {liker['name']} liked you!"
            print(f"Like notification: {notification_text}")
            
    except Exception as e:
        print(f"Error sending like notification: {e}")
import os
import aiohttp
import json
from typing import Optional

class FCMNotificationService:
    def __init__(self):
        self.server_key = os.getenv('FCM_SERVER_KEY')
        self.fcm_url = 'https://fcm.googleapis.com/fcm/send'
    
    async def send_notification(
        self,
        fcm_token: str,
        title: str,
        body: str,
        data: dict = None
    ) -> bool:
        """Send FCM notification to user"""
        if not self.server_key:
            print("⚠️ FCM_SERVER_KEY not configured")
            return False
        
        headers = {
            'Authorization': f'key={self.server_key}',
            'Content-Type': 'application/json',
        }
        
        payload = {
            'to': fcm_token,
            'notification': {
                'title': title,
                'body': body,
                'sound': 'default',
                'badge': '1',
            },
            'priority': 'high',
            'data': data or {}
        }
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(self.fcm_url, headers=headers, json=payload) as response:
                    if response.status == 200:
                        print(f"✅ Notification sent: {title}")
                        return True
                    else:
                        print(f"❌ FCM error: {response.status}")
                        return False
        except Exception as e:
            print(f"❌ Notification failed: {e}")
            return False
    
    async def send_match_notification(self, fcm_token: str, matched_user_name: str):
        """Send match notification"""
        return await self.send_notification(
            fcm_token=fcm_token,
            title="🎉 It's a Match!",
            body=f"You and {matched_user_name} liked each other!",
            data={'type': 'match', 'user_name': matched_user_name}
        )
    
    async def send_message_notification(
        self,
        fcm_token: str,
        sender_name: str,
        message_preview: str
    ):
        """Send new message notification"""
        preview = message_preview[:50] + '...' if len(message_preview) > 50 else message_preview
        return await self.send_notification(
            fcm_token=fcm_token,
            title=f"💬 {sender_name}",
            body=preview,
            data={'type': 'message', 'sender': sender_name}
        )
    
    async def send_like_notification(self, fcm_token: str):
        """Send like received notification"""
        return await self.send_notification(
            fcm_token=fcm_token,
            title="❤️ Someone liked you!",
            body="Check who's interested in you",
            data={'type': 'like'}
        )
    
    async def send_profile_view_notification(self, fcm_token: str, viewer_name: str):
        """Send profile view notification"""
        return await self.send_notification(
            fcm_token=fcm_token,
            title="👀 Profile View",
            body=f"{viewer_name} viewed your profile",
            data={'type': 'profile_view', 'viewer': viewer_name}
        )

# Global instance
fcm_service = FCMNotificationService()

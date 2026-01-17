import os
import aiohttp
import json
from typing import Optional

class FCMNotificationService:
    def __init__(self):
        # Try V1 API first, fallback to Legacy
        self.use_legacy = not os.path.exists('heartlink-c3c2d-firebase-adminsdk-fbsvc-9739f1a00e.json')
        
        if self.use_legacy:
            # Legacy API
            self.server_key = os.getenv('FCM_SERVER_KEY')
            self.fcm_url = 'https://fcm.googleapis.com/fcm/send'
            print("📱 Using FCM Legacy API")
        else:
            # V1 API
            self.project_id = os.getenv('FIREBASE_PROJECT_ID', 'heartlink-c3c2d')
            self.fcm_url = f'https://fcm.googleapis.com/v1/projects/{self.project_id}/messages:send'
            print("📱 Using FCM V1 API")
    
    async def send_notification(
        self,
        fcm_token: str,
        title: str,
        body: str,
        data: dict = None
    ) -> bool:
        """Send FCM notification (auto-detects Legacy or V1)"""
        if not fcm_token:
            print("⚠️ No FCM token provided")
            return False
        
        if self.use_legacy:
            return await self._send_legacy(fcm_token, title, body, data)
        else:
            return await self._send_v1(fcm_token, title, body, data)
    
    async def _send_legacy(self, fcm_token: str, title: str, body: str, data: dict = None) -> bool:
        """Send using Legacy API (Server Key)"""
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
            },
            'priority': 'high',
            'data': data or {},
            'android': {
                'priority': 'high',
                'notification': {
                    'sound': 'default',
                    'channel_id': 'heartlink_channel'
                }
            }
        }
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.post(self.fcm_url, headers=headers, json=payload) as response:
                    result = await response.json()
                    if response.status == 200 and result.get('success', 0) > 0:
                        print(f"✅ Notification sent: {title}")
                        return True
                    else:
                        print(f"❌ FCM error: {response.status} - {result}")
                        return False
        except Exception as e:
            print(f"❌ Notification failed: {e}")
            return False
    
    async def _send_v1(self, fcm_token: str, title: str, body: str, data: dict = None) -> bool:
        """Send using V1 API (Service Account)"""
        try:
            from google.oauth2 import service_account
            from google.auth.transport.requests import Request
            
            credentials = service_account.Credentials.from_service_account_file(
                'heartlink-c3c2d-firebase-adminsdk-fbsvc-9739f1a00e.json',
                scopes=['https://www.googleapis.com/auth/firebase.messaging']
            )
            credentials.refresh(Request())
            
            headers = {
                'Authorization': f'Bearer {credentials.token}',
                'Content-Type': 'application/json',
            }
            
            payload = {
                'message': {
                    'token': fcm_token,
                    'notification': {'title': title, 'body': body},
                    'data': data or {},
                    'android': {'priority': 'high'}
                }
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.post(self.fcm_url, headers=headers, json=payload) as response:
                    if response.status == 200:
                        print(f"✅ Notification sent: {title}")
                        return True
                    else:
                        print(f"❌ FCM error: {response.status}")
                        return False
        except Exception as e:
            print(f"❌ V1 API failed: {e}")
            return False
    
    async def send_match_notification(self, fcm_token: str, matched_user_name: str):
        """Send match notification"""
        return await self.send_notification(
            fcm_token=fcm_token,
            title="🎉 It's a Match!",
            body=f"You and {matched_user_name} liked each other!",
            data={'type': 'match', 'user_name': matched_user_name}
        )
    
    async def send_message_notification(self, fcm_token: str, sender_name: str, message_content: str):
        """Send new message notification"""
        preview = message_content[:50] + '...' if len(message_content) > 50 else message_content
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

# Global instance
fcm_service = FCMNotificationService()

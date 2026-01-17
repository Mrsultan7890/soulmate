import os
import aiohttp
import json
from datetime import datetime
from typing import Optional

class TelegramService:
    def __init__(self):
        self.bot_token = os.getenv('TELEGRAM_BOT_TOKEN')
        self.admin_chat_id = os.getenv('TELEGRAM_ADMIN_CHAT_ID', '@storagecat')
        self.base_url = f"https://api.telegram.org/bot{self.bot_token}"
    
    async def send_report_notification(self, report_data: dict):
        """Send user report notification to admin"""
        try:
            message = self._format_report_message(report_data)
            await self._send_message(self.admin_chat_id, message)
        except Exception as e:
            print(f"Failed to send Telegram notification: {e}")
    
    async def send_suspicious_activity_alert(self, activity_data: dict):
        """Send suspicious activity alert to admin"""
        try:
            message = self._format_suspicious_activity_message(activity_data)
            await self._send_message(self.admin_chat_id, message)
        except Exception as e:
            print(f"Failed to send suspicious activity alert: {e}")
    
    def _format_report_message(self, report_data: dict) -> str:
        """Format user report message"""
        return f"""🚨 **USER REPORT ALERT** 🚨

**Reported User ID:** {report_data.get('reported_user_id')}
**Reporter ID:** {report_data.get('reporter_id')}
**Reason:** {report_data.get('reason')}
**Time:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

**Evidence:**
{json.dumps(report_data.get('evidence', {}), indent=2)}

**Action Required:** Please review this report immediately.
"""
    
    def _format_suspicious_activity_message(self, activity_data: dict) -> str:
        """Format suspicious activity message"""
        return f"""⚠️ **SUSPICIOUS ACTIVITY DETECTED** ⚠️

**User ID:** {activity_data.get('user_id')}
**Activity Type:** {activity_data.get('activity_type')}
**Risk Score:** {activity_data.get('risk_score')}/100
**Flags:** {', '.join(activity_data.get('flags', []))}
**Time:** {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

**Message Content:** 
"{activity_data.get('message_content', 'N/A')}"

**Auto-Action:** {activity_data.get('auto_action', 'None')}
"""
    
    async def _send_message(self, chat_id: str, message: str):
        """Send message via Telegram Bot API"""
        url = f"{self.base_url}/sendMessage"
        
        payload = {
            'chat_id': chat_id,
            'text': message,
            'parse_mode': 'Markdown'
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(url, json=payload) as response:
                if response.status != 200:
                    raise Exception(f"Telegram API error: {response.status}")
                return await response.json()
    
    async def get_file_url(self, file_id: str) -> str:
        """Get file URL from Telegram"""
        try:
            print(f"[TelegramService] Getting file URL for: {file_id[:50]}...")
            print(f"[TelegramService] Bot token: {self.bot_token[:20]}...")
            
            url = f"{self.base_url}/getFile"
            async with aiohttp.ClientSession() as session:
                async with session.get(url, params={'file_id': file_id}) as response:
                    print(f"[TelegramService] Response status: {response.status}")
                    
                    if response.status == 200:
                        data = await response.json()
                        print(f"[TelegramService] Response data: {data}")
                        
                        if data.get('ok'):
                            file_path = data['result']['file_path']
                            final_url = f"https://api.telegram.org/file/bot{self.bot_token}/{file_path}"
                            print(f"[TelegramService] Final URL: {final_url[:80]}...")
                            return final_url
                        else:
                            print(f"[TelegramService] API returned ok=false: {data}")
                    else:
                        error_text = await response.text()
                        print(f"[TelegramService] Error response: {error_text}")
            
            print(f"[TelegramService] Returning placeholder (no success)")
            return "https://via.placeholder.com/400x400/FF6B6B/FFFFFF?text=HeartLink"
        except Exception as e:
            print(f"[TelegramService] Exception: {e}")
            import traceback
            traceback.print_exc()
            return "https://via.placeholder.com/400x400/FF6B6B/FFFFFF?text=HeartLink"
    
    async def upload_image_from_base64(self, base64_data: str) -> str:
        """Upload base64 image to Telegram and return file_id"""
        try:
            import base64
            import io
            
            # Remove data:image prefix if present
            if 'base64,' in base64_data:
                base64_data = base64_data.split('base64,')[1]
            
            # Decode base64
            image_bytes = base64.b64decode(base64_data)
            
            # Upload to Telegram
            url = f"{self.base_url}/sendPhoto"
            data = aiohttp.FormData()
            data.add_field('chat_id', self.admin_chat_id)
            data.add_field('photo', io.BytesIO(image_bytes), filename='image.jpg')
            
            async with aiohttp.ClientSession() as session:
                async with session.post(url, data=data) as response:
                    if response.status == 200:
                        result = await response.json()
                        if result.get('ok'):
                            # Get file_id from largest photo
                            photos = result['result']['photo']
                            file_id = photos[-1]['file_id']
                            print(f"[TelegramService] Image uploaded, file_id: {file_id[:50]}...")
                            return file_id
            
            raise Exception("Upload failed")
        except Exception as e:
            print(f"[TelegramService] Upload error: {e}")
            raise

# Global instance
telegram_service = TelegramService()


async def upload_image_to_telegram(image_data: str, is_base64: bool = True):
    """Helper function to upload image"""
    try:
        if is_base64:
            return await telegram_service.upload_image_from_base64(image_data)
        else:
            return await telegram_service.send_photo(image_data)
    except Exception as e:
        print(f"Upload failed: {e}")
        return f"placeholder_file_id_{hash(image_data[:100]) % 10000}"

async def get_image_url(file_id: str):
    """Helper function to get image URL"""
    try:
        print(f"[get_image_url] Fetching URL for file_id: {file_id[:50]}...")
        
        if file_id.startswith('placeholder_'):
            print(f"[get_image_url] Placeholder detected, returning placeholder URL")
            return "https://via.placeholder.com/400x400/FF6B6B/FFFFFF?text=HeartLink"
        
        url = await telegram_service.get_file_url(file_id)
        print(f"[get_image_url] Got URL: {url[:80]}...")
        return url
    except Exception as e:
        print(f"[get_image_url] ERROR: {e}")
        import traceback
        traceback.print_exc()
        return "https://via.placeholder.com/400x400/FF6B6B/FFFFFF?text=HeartLink"

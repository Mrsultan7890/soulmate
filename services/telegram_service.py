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

# Global instance
telegram_service = TelegramService()
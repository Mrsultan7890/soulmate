import aiohttp
import asyncio
import base64
import io
from config.settings import settings

class TelegramService:
    def __init__(self):
        self.bot_token = settings.TELEGRAM_BOT_TOKEN
        self.chat_id = settings.TELEGRAM_CHAT_ID
        self.base_url = f"https://api.telegram.org/bot{self.bot_token}"
    
    async def send_photo(self, photo_url: str, caption: str = None):
        """Send photo to Telegram and get file_id"""
        try:
            async with aiohttp.ClientSession() as session:
                data = {
                    'chat_id': self.chat_id,
                    'photo': photo_url
                }
                if caption:
                    data['caption'] = caption
                
                async with session.post(f"{self.base_url}/sendPhoto", data=data) as response:
                    result = await response.json()
                    
                    if result.get('ok'):
                        # Get the largest photo size
                        photos = result['result']['photo']
                        largest_photo = max(photos, key=lambda x: x['file_size'])
                        return largest_photo['file_id']
                    else:
                        error_msg = result.get('description', 'Unknown error')
                        print(f"Telegram API error: {error_msg}")
                        raise Exception(f"Telegram API error: {error_msg}")
                        
        except Exception as e:
            print(f"Error sending photo to Telegram: {e}")
            raise
    
    async def get_file_url(self, file_id: str):
        """Get file URL from Telegram file_id"""
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(f"{self.base_url}/getFile?file_id={file_id}") as response:
                    result = await response.json()
                    
                    if result.get('ok'):
                        file_path = result['result']['file_path']
                        return f"https://api.telegram.org/file/bot{self.bot_token}/{file_path}"
                    else:
                        error_msg = result.get('description', 'Unknown error')
                        print(f"Telegram API error: {error_msg}")
                        raise Exception(f"Telegram API error: {error_msg}")
                        
        except Exception as e:
            print(f"Error getting file URL from Telegram: {e}")
            raise
    
    async def upload_image_from_base64(self, base64_data: str, filename: str = "image.jpg"):
        """Upload base64 image to Telegram"""
        try:
            # Remove data URL prefix if present
            if base64_data.startswith('data:'):
                base64_data = base64_data.split(',')[1]
            
            # Decode base64
            image_data = base64.b64decode(base64_data)
            
            async with aiohttp.ClientSession() as session:
                data = aiohttp.FormData()
                data.add_field('chat_id', self.chat_id)
                data.add_field('photo', io.BytesIO(image_data), filename=filename, content_type='image/jpeg')
                
                async with session.post(f"{self.base_url}/sendPhoto", data=data) as response:
                    result = await response.json()
                    
                    if result.get('ok'):
                        photos = result['result']['photo']
                        largest_photo = max(photos, key=lambda x: x['file_size'])
                        return largest_photo['file_id']
                    else:
                        error_msg = result.get('description', 'Unknown error')
                        print(f"Telegram API error: {error_msg}")
                        raise Exception(f"Telegram API error: {error_msg}")
                        
        except Exception as e:
            print(f"Error uploading image to Telegram: {e}")
            raise
    
    async def test_connection(self):
        """Test Telegram bot connection"""
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(f"{self.base_url}/getMe") as response:
                    result = await response.json()
                    return result.get('ok', False)
        except Exception as e:
            print(f"Error testing Telegram connection: {e}")
            return False

# Global instance
telegram_service = TelegramService()

async def upload_image_to_telegram(image_data: str, is_base64: bool = True):
    """Helper function to upload image"""
    try:
        # Test connection first
        if not await telegram_service.test_connection():
            raise Exception("Telegram bot connection failed")
        
        if is_base64:
            return await telegram_service.upload_image_from_base64(image_data)
        else:
            return await telegram_service.send_photo(image_data)
    except Exception as e:
        print(f"Upload failed: {e}")
        # Return a placeholder file_id for development
        return f"placeholder_file_id_{hash(image_data[:100]) % 10000}"

async def get_image_url(file_id: str):
    """Helper function to get image URL"""
    try:
        if file_id.startswith('placeholder_'):
            # Return a placeholder image URL
            return "https://via.placeholder.com/400x400/FF6B6B/FFFFFF?text=HeartLink"
        return await telegram_service.get_file_url(file_id)
    except Exception as e:
        print(f"Get URL failed: {e}")
        return "https://via.placeholder.com/400x400/FF6B6B/FFFFFF?text=HeartLink"
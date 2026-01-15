from typing import Optional
from config.database import db

class PhotoPrivacyService:
    
    @staticmethod
    async def should_blur_photos(viewer_id: int, profile_owner_id: int) -> bool:
        """Check if photos should be blurred for this viewer"""
        
        # Don't blur own photos
        if viewer_id == profile_owner_id:
            return False
        
        # Check if users are matched
        match = await db.fetchone("""
            SELECT id FROM matches 
            WHERE (user1_id = ? AND user2_id = ?) 
            OR (user1_id = ? AND user2_id = ?)
        """, (viewer_id, profile_owner_id, profile_owner_id, viewer_id))
        
        # If matched, don't blur
        if match:
            return False
        
        # Check if profile owner has blur enabled
        user_settings = await db.fetchone("""
            SELECT preferences FROM users WHERE id = ?
        """, (profile_owner_id,))
        
        if user_settings and user_settings[0]:
            import json
            prefs = json.loads(user_settings[0])
            return prefs.get('blur_photos_until_match', True)  # Default: blur enabled
        
        return True  # Default: blur photos
    
    @staticmethod
    async def get_photo_url(photo_id: str, viewer_id: int, profile_owner_id: int) -> dict:
        """Get photo URL with blur status"""
        should_blur = await PhotoPrivacyService.should_blur_photos(viewer_id, profile_owner_id)
        
        return {
            'photo_id': photo_id,
            'url': f"https://api.telegram.org/file/bot{photo_id}",
            'is_blurred': should_blur,
            'blur_level': 'medium' if should_blur else 'none'
        }
    
    @staticmethod
    async def update_blur_preference(user_id: int, blur_enabled: bool):
        """Update user's photo blur preference"""
        # Get current preferences
        current_prefs = await db.fetchone("""
            SELECT preferences FROM users WHERE id = ?
        """, (user_id,))
        
        import json
        if current_prefs and current_prefs[0]:
            prefs = json.loads(current_prefs[0])
        else:
            prefs = {}
        
        prefs['blur_photos_until_match'] = blur_enabled
        
        await db.execute("""
            UPDATE users SET preferences = ? WHERE id = ?
        """, (json.dumps(prefs), user_id))
        
        await db.commit()
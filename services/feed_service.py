from ..config.database import get_db
import json

class FeedService:
    @staticmethod
    async def refresh_user_feed_posts(user_id: int, profile_images: list):
        """Refresh user's feed posts when profile images are updated"""
        db = await get_db()
        
        try:
            # Deactivate existing posts
            await db.execute("""
                UPDATE feed_posts SET is_active = 0 WHERE user_id = ?
            """, (user_id,))
            
            # Add new posts for each profile image
            for img_id in profile_images:
                await db.execute("""
                    INSERT INTO feed_posts (user_id, image_file_id) VALUES (?, ?)
                """, (user_id, img_id))
            
            await db.commit()
            return True
        except Exception as e:
            print(f"Error refreshing feed posts: {e}")
            return False
    
    @staticmethod
    async def create_user_settings(user_id: int):
        """Create default settings for new user"""
        db = await get_db()
        
        try:
            await db.execute("""
                INSERT OR IGNORE INTO user_settings 
                (user_id, feed_visibility, show_in_feed, notifications_enabled, location_sharing)
                VALUES (?, 1, 1, 1, 1)
            """, (user_id,))
            await db.commit()
            return True
        except Exception as e:
            print(f"Error creating user settings: {e}")
            return False

feed_service = FeedService()
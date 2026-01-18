from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional
from config.database import get_db
from routes.auth import get_current_user

router = APIRouter(prefix="/api/settings", tags=["settings"])

class UserSettings(BaseModel):
    feed_visibility: bool
    show_in_feed: bool
    notifications_enabled: bool
    location_sharing: bool

class UpdateSettings(BaseModel):
    feed_visibility: Optional[bool] = None
    show_in_feed: Optional[bool] = None
    notifications_enabled: Optional[bool] = None
    location_sharing: Optional[bool] = None

@router.get("/", response_model=UserSettings)
async def get_user_settings(
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Get user settings"""
    settings = await db.fetchone("""
        SELECT feed_visibility, show_in_feed, notifications_enabled, location_sharing
        FROM user_settings WHERE user_id = ?
    """, (current_user["id"],))
    
    if not settings:
        # Create default settings
        await db.execute("""
            INSERT INTO user_settings (user_id, feed_visibility, show_in_feed, notifications_enabled, location_sharing)
            VALUES (?, 1, 1, 1, 1)
        """, (current_user["id"],))
        await db.commit()
        
        return UserSettings(
            feed_visibility=True,
            show_in_feed=True,
            notifications_enabled=True,
            location_sharing=True
        )
    
    return UserSettings(
        feed_visibility=bool(settings["feed_visibility"]),
        show_in_feed=bool(settings["show_in_feed"]),
        notifications_enabled=bool(settings["notifications_enabled"]),
        location_sharing=bool(settings["location_sharing"])
    )

@router.put("/")
async def update_user_settings(
    settings_update: UpdateSettings,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Update user settings"""
    # Check if settings exist
    existing = await db.fetchone("""
        SELECT id FROM user_settings WHERE user_id = ?
    """, (current_user["id"],))
    
    if not existing:
        # Create default settings first
        await db.execute("""
            INSERT INTO user_settings (user_id) VALUES (?)
        """, (current_user["id"],))
    
    # Update settings
    update_fields = []
    params = []
    
    if settings_update.feed_visibility is not None:
        update_fields.append("feed_visibility = ?")
        params.append(settings_update.feed_visibility)
    
    if settings_update.show_in_feed is not None:
        update_fields.append("show_in_feed = ?")
        params.append(settings_update.show_in_feed)
    
    if settings_update.notifications_enabled is not None:
        update_fields.append("notifications_enabled = ?")
        params.append(settings_update.notifications_enabled)
    
    if settings_update.location_sharing is not None:
        update_fields.append("location_sharing = ?")
        params.append(settings_update.location_sharing)
    
    if update_fields:
        update_fields.append("updated_at = CURRENT_TIMESTAMP")
        params.append(current_user["id"])
        
        query = f"""
            UPDATE user_settings 
            SET {', '.join(update_fields)}
            WHERE user_id = ?
        """
        
        await db.execute(query, params)
        await db.commit()
    
    return {"message": "Settings updated successfully"}

@router.post("/toggle-feed-visibility")
async def toggle_feed_visibility(
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Toggle feed visibility setting"""
    # Get current setting
    current_setting = await db.fetchone("""
        SELECT show_in_feed FROM user_settings WHERE user_id = ?
    """, (current_user["id"],))
    
    if not current_setting:
        # Create with default (visible)
        await db.execute("""
            INSERT INTO user_settings (user_id, show_in_feed) VALUES (?, 0)
        """, (current_user["id"],))
        new_value = False
    else:
        # Toggle current value
        new_value = not bool(current_setting["show_in_feed"])
        await db.execute("""
            UPDATE user_settings SET show_in_feed = ? WHERE user_id = ?
        """, (new_value, current_user["id"]))
    
    await db.commit()
    
    return {
        "show_in_feed": new_value,
        "message": f"Feed visibility {'enabled' if new_value else 'disabled'}"
    }
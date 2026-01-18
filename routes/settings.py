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

class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str

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

@router.post("/change-password")
async def change_password(
    request: ChangePasswordRequest,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Change user password"""
    from routes.auth import verify_password, get_password_hash
    
    # Verify current password
    user = await db.fetchone("""
        SELECT password_hash FROM users WHERE id = ?
    """, (current_user["id"],))
    
    if not verify_password(request.current_password, user["password_hash"]):
        raise HTTPException(status_code=400, detail="Current password is incorrect")
    
    # Validate new password
    if len(request.new_password) < 6:
        raise HTTPException(status_code=400, detail="New password must be at least 6 characters")
    
    # Update password
    new_hash = get_password_hash(request.new_password)
    await db.execute("""
        UPDATE users SET password_hash = ? WHERE id = ?
    """, (new_hash, current_user["id"]))
    await db.commit()
    
    return {"message": "Password changed successfully"}

@router.delete("/delete-account")
async def delete_account(
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Delete user account permanently"""
    try:
        # Delete user data in order (foreign key constraints)
        await db.execute("DELETE FROM feed_likes WHERE user_id = ?", (current_user["id"],))
        await db.execute("DELETE FROM feed_favorites WHERE user_id = ?", (current_user["id"],))
        await db.execute("DELETE FROM feed_posts WHERE user_id = ?", (current_user["id"],))
        await db.execute("DELETE FROM user_settings WHERE user_id = ?", (current_user["id"],))
        await db.execute("DELETE FROM messages WHERE sender_id = ?", (current_user["id"],))
        await db.execute("DELETE FROM matches WHERE user1_id = ? OR user2_id = ?", (current_user["id"], current_user["id"]))
        await db.execute("DELETE FROM swipes WHERE swiper_id = ? OR swiped_id = ?", (current_user["id"], current_user["id"]))
        await db.execute("DELETE FROM profile_views WHERE viewer_id = ? OR viewed_id = ?", (current_user["id"], current_user["id"]))
        await db.execute("DELETE FROM users WHERE id = ?", (current_user["id"],))
        await db.commit()
        
        return {"message": "Account deleted successfully"}
    except Exception as e:
        print(f"Error deleting account: {e}")
        raise HTTPException(status_code=500, detail="Failed to delete account")

@router.get("/account-info")
async def get_account_info(
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Get account information"""
    user = await db.fetchone("""
        SELECT email, name, created_at, is_verified, is_premium, flag_count
        FROM users WHERE id = ?
    """, (current_user["id"],))
    
    # Get stats
    matches_count = await db.fetchone("""
        SELECT COUNT(*) as count FROM matches 
        WHERE user1_id = ? OR user2_id = ?
    """, (current_user["id"], current_user["id"]))
    
    profile_views = await db.fetchone("""
        SELECT COUNT(*) as count FROM profile_views 
        WHERE viewed_id = ?
    """, (current_user["id"],))
    
    return {
        "email": user["email"],
        "name": user["name"],
        "member_since": user["created_at"],
        "is_verified": bool(user["is_verified"]),
        "is_premium": bool(user["is_premium"]),
        "flag_count": user["flag_count"],
        "total_matches": matches_count["count"],
        "profile_views": profile_views["count"]
    }
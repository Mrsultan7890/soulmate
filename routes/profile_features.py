from fastapi import APIRouter, Depends, HTTPException
from datetime import datetime, timedelta
import json

from routes.auth import get_current_user
from config.database import get_db

router = APIRouter()

@router.get("/profile-completion")
async def get_profile_completion(
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Calculate profile completion percentage"""
    score = 0
    total_fields = 15
    
    # Basic info (5 fields)
    if current_user.get("name"): score += 1
    if current_user.get("age"): score += 1
    if current_user.get("bio") and len(current_user["bio"]) > 20: score += 1
    if current_user.get("location"): score += 1
    
    # Profile images (1 field)
    images = json.loads(current_user.get("profile_images", "[]"))
    if len(images) >= 3: score += 1
    
    # Interests (1 field)
    interests = json.loads(current_user.get("interests", "[]"))
    if len(interests) >= 3: score += 1
    
    # Relationship intent (1 field)
    if current_user.get("relationship_intent"): score += 1
    
    # Job & Education (2 fields)
    if current_user.get("job_title"): score += 1
    if current_user.get("education_level"): score += 1
    
    # Physical attributes (2 fields)
    if current_user.get("height"): score += 1
    if current_user.get("body_type"): score += 1
    
    # Lifestyle (3 fields)
    if current_user.get("smoking"): score += 1
    if current_user.get("drinking"): score += 1
    if current_user.get("diet_preference"): score += 1
    
    percentage = int((score / total_fields) * 100)
    
    missing_fields = []
    if not current_user.get("bio") or len(current_user.get("bio", "")) < 20:
        missing_fields.append("bio")
    if len(images) < 3:
        missing_fields.append("photos")
    if len(interests) < 3:
        missing_fields.append("interests")
    if not current_user.get("job_title"):
        missing_fields.append("job")
    if not current_user.get("education_level"):
        missing_fields.append("education")
    
    return {
        "percentage": percentage,
        "completed_fields": score,
        "total_fields": total_fields,
        "missing_fields": missing_fields
    }

@router.post("/update-activity")
async def update_last_active(
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Update user's last active timestamp"""
    await db.execute(
        "UPDATE users SET last_active = CURRENT_TIMESTAMP WHERE id = ?",
        (current_user["id"],)
    )
    await db.commit()
    return {"updated": True}

@router.get("/activity-status/{user_id}")
async def get_activity_status(
    user_id: int,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Get user's activity status"""
    user = await db.fetchone(
        "SELECT last_active FROM users WHERE id = ?",
        (user_id,)
    )
    
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    last_active = datetime.fromisoformat(user["last_active"])
    now = datetime.now()
    diff = now - last_active
    
    if diff.total_seconds() < 300:  # 5 minutes
        status = "Active now"
        is_online = True
    elif diff.total_seconds() < 3600:  # 1 hour
        minutes = int(diff.total_seconds() / 60)
        status = f"Active {minutes}m ago"
        is_online = False
    elif diff.total_seconds() < 86400:  # 24 hours
        hours = int(diff.total_seconds() / 3600)
        status = f"Active {hours}h ago"
        is_online = False
    else:
        days = int(diff.total_seconds() / 86400)
        status = f"Active {days}d ago"
        is_online = False
    
    return {
        "status": status,
        "is_online": is_online,
        "last_active": user["last_active"]
    }

@router.post("/share-location")
async def share_location(
    request: dict,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Share live location with another user"""
    shared_with_user_id = request.get("shared_with_user_id")
    duration_hours = request.get("duration_hours", 2)
    emergency_contact_name = request.get("emergency_contact_name")
    emergency_contact_phone = request.get("emergency_contact_phone")
    
    if not shared_with_user_id:
        raise HTTPException(status_code=400, detail="shared_with_user_id required")
    
    # Get current location
    latitude = current_user.get("latitude")
    longitude = current_user.get("longitude")
    
    if not latitude or not longitude:
        raise HTTPException(status_code=400, detail="Location not available")
    
    # Calculate expiry
    expires_at = datetime.now() + timedelta(hours=duration_hours)
    
    # Deactivate old shares
    await db.execute(
        "UPDATE location_shares SET is_active = FALSE WHERE user_id = ? AND shared_with_user_id = ?",
        (current_user["id"], shared_with_user_id)
    )
    
    # Create new share
    await db.execute(
        """INSERT INTO location_shares 
        (user_id, shared_with_user_id, latitude, longitude, expires_at, emergency_contact_name, emergency_contact_phone)
        VALUES (?, ?, ?, ?, ?, ?, ?)""",
        (current_user["id"], shared_with_user_id, latitude, longitude, expires_at.isoformat(), 
         emergency_contact_name, emergency_contact_phone)
    )
    await db.commit()
    
    return {
        "message": "Location shared successfully",
        "expires_at": expires_at.isoformat(),
        "duration_hours": duration_hours
    }

@router.get("/shared-location/{user_id}")
async def get_shared_location(
    user_id: int,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Get shared location from another user"""
    share = await db.fetchone(
        """SELECT * FROM location_shares 
        WHERE user_id = ? AND shared_with_user_id = ? AND is_active = TRUE
        AND expires_at > datetime('now')""",
        (user_id, current_user["id"])
    )
    
    if not share:
        return {"shared": False}
    
    return {
        "shared": True,
        "latitude": share["latitude"],
        "longitude": share["longitude"],
        "expires_at": share["expires_at"],
        "emergency_contact": {
            "name": share["emergency_contact_name"],
            "phone": share["emergency_contact_phone"]
        } if share["emergency_contact_name"] else None
    }

@router.post("/stop-sharing-location/{user_id}")
async def stop_sharing_location(
    user_id: int,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Stop sharing location with a user"""
    await db.execute(
        "UPDATE location_shares SET is_active = FALSE WHERE user_id = ? AND shared_with_user_id = ?",
        (current_user["id"], user_id)
    )
    await db.commit()
    
    return {"message": "Location sharing stopped"}

@router.get("/my-location-shares")
async def get_my_location_shares(
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Get all active location shares"""
    shares = await db.fetchall(
        """SELECT ls.*, u.name, u.profile_images 
        FROM location_shares ls
        JOIN users u ON ls.shared_with_user_id = u.id
        WHERE ls.user_id = ? AND ls.is_active = TRUE AND ls.expires_at > datetime('now')""",
        (current_user["id"],)
    )
    
    result = []
    for share in shares:
        result.append({
            "shared_with_user_id": share["shared_with_user_id"],
            "shared_with_name": share["name"],
            "expires_at": share["expires_at"],
            "created_at": share["created_at"]
        })
    
    return {"active_shares": result}

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from routes.auth import get_current_user
from config.database import get_db

router = APIRouter()

class FCMTokenRequest(BaseModel):
    fcm_token: str

@router.post("/fcm-token")
async def save_fcm_token(
    request: FCMTokenRequest,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Save user's FCM token for push notifications"""
    try:
        await db.execute(
            "UPDATE users SET fcm_token = ? WHERE id = ?",
            (request.fcm_token, current_user["id"])
        )
        await db.commit()
        
        return {"message": "FCM token saved successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to save FCM token: {str(e)}")

@router.delete("/fcm-token")
async def delete_fcm_token(
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Delete user's FCM token (on logout)"""
    try:
        await db.execute(
            "UPDATE users SET fcm_token = NULL WHERE id = ?",
            (current_user["id"],)
        )
        await db.commit()
        
        return {"message": "FCM token deleted"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to delete FCM token: {str(e)}")

@router.post("/test-notification")
async def test_notification(
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Test FCM notification for current user"""
    try:
        from services.fcm_notification_service import fcm_service
        
        user = await db.fetchone("SELECT fcm_token, name FROM users WHERE id = ?", (current_user["id"],))
        
        if not user or not user['fcm_token']:
            return {
                "success": False,
                "message": "No FCM token found for user",
                "user_id": current_user["id"],
                "fcm_token": user['fcm_token'] if user else None
            }
        
        result = await fcm_service.send_notification(
            fcm_token=user['fcm_token'],
            title="🔔 Test Notification",
            body="Your notifications are working perfectly!",
            data={'type': 'test'}
        )
        
        return {
            "success": result,
            "message": "Notification sent" if result else "Failed to send notification",
            "user_id": current_user["id"],
            "fcm_token": user['fcm_token'][:20] + "..."
        }
    except Exception as e:
        return {
            "success": False,
            "message": f"Error: {str(e)}",
            "user_id": current_user["id"]
        }

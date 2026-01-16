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

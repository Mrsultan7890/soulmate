from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from routes.auth import get_current_user
from config.database import get_db
from services.gender_detection_service import gender_detection_service

router = APIRouter()

class GenderVerificationRequest(BaseModel):
    image_base64: str
    detected_gender: str  # 'male' or 'female' from mobile ML model

class GenderVerificationResponse(BaseModel):
    success: bool
    message: str
    is_verified: bool
    gender: str

@router.post("/verify-gender", response_model=GenderVerificationResponse)
async def verify_gender(
    request: GenderVerificationRequest,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """
    Verify user's gender using face photo
    Mobile app sends detected gender + face image for verification
    """
    try:
        # Check if already verified
        user = await db.fetchone(
            "SELECT is_verified, gender FROM users WHERE id = ?",
            (current_user["id"],)
        )
        
        if user and user['is_verified']:
            return GenderVerificationResponse(
                success=False,
                message="Already verified. Gender cannot be changed.",
                is_verified=True,
                gender=user['gender']
            )
        
        # Validate gender value
        if request.detected_gender not in ['male', 'female']:
            raise HTTPException(status_code=400, detail="Invalid gender value")
        
        # Verify face in image
        verification_result = await gender_detection_service.verify_and_detect_gender(
            request.image_base64
        )
        
        if not verification_result['has_face']:
            return GenderVerificationResponse(
                success=False,
                message=verification_result['message'],
                is_verified=False,
                gender=""
            )
        
        # Store verification result
        success = await gender_detection_service.store_verification_result(
            user_id=current_user["id"],
            gender=request.detected_gender,
            confidence=verification_result['confidence'],
            db=db
        )
        
        if not success:
            raise HTTPException(status_code=500, detail="Failed to store verification")
        
        return GenderVerificationResponse(
            success=True,
            message=f"Successfully verified as {request.detected_gender}",
            is_verified=True,
            gender=request.detected_gender
        )
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Verification failed: {str(e)}")

@router.get("/verification-status")
async def get_verification_status(
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Get user's verification status"""
    try:
        user = await db.fetchone(
            "SELECT is_verified, gender, verified_at FROM users WHERE id = ?",
            (current_user["id"],)
        )
        
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        return {
            "is_verified": bool(user['is_verified']),
            "gender": user['gender'],
            "verified_at": user['verified_at']
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

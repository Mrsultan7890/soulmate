from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from typing import Optional

from routes.auth import get_current_user
from config.database import get_db
from services.face_verification_service import face_service

router = APIRouter()

class FaceVerificationRequest(BaseModel):
    image_data: str  # base64 image
    verification_type: str = "gender_detection"  # or "face_match"

class FaceMatchRequest(BaseModel):
    profile_image: str  # base64 of profile image
    live_image: str     # base64 of live capture

@router.post("/detect-gender")
async def detect_gender(
    request: FaceVerificationRequest,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Detect gender from face image"""
    try:
        # Convert base64 to image and detect gender
        img_array = face_service.base64_to_image(request.image_data)
        gender, confidence = face_service.detect_gender_simple(img_array)
        
        if gender is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=confidence  # Error message
            )
        
        # Generate avatar data
        avatar_data = face_service.create_avatar_data(gender, request.image_data)
        
        # Update user's gender and avatar in database
        await db.execute(
            "UPDATE users SET gender = ?, avatar_data = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
            (gender, str(avatar_data), current_user["id"])
        )
        await db.commit()
        
        return {
            "gender": gender,
            "confidence": confidence,
            "avatar_data": avatar_data,
            "message": f"Gender detected as {gender}"
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Face detection failed: {str(e)}"
        )

@router.post("/verify-face")
async def verify_face(
    request: FaceMatchRequest,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Verify if live image matches profile image"""
    try:
        # Compare faces
        is_match, details = face_service.verify_face_match(
            request.profile_image, 
            request.live_image
        )
        
        if is_match:
            # Update verification status
            await db.execute(
                "UPDATE users SET is_face_verified = TRUE, face_verified_at = CURRENT_TIMESTAMP WHERE id = ?",
                (current_user["id"],)
            )
            await db.commit()
            
            return {
                "verified": True,
                "message": "Face verification successful",
                "details": details
            }
        else:
            return {
                "verified": False,
                "message": "Face verification failed",
                "details": details
            }
            
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Face verification failed: {str(e)}"
        )

@router.post("/check-duplicate")
async def check_duplicate_face(
    request: FaceVerificationRequest,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Check if face already exists in database"""
    try:
        # Generate face hash
        face_hash = face_service.generate_face_hash(request.image_data)
        
        if not face_hash:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="No face detected in image"
            )
        
        # Check if hash exists
        existing_user = await db.fetchone(
            "SELECT id, name FROM users WHERE face_hash = ? AND id != ?",
            (face_hash, current_user["id"])
        )
        
        if existing_user:
            return {
                "is_duplicate": True,
                "message": "This face is already registered with another account",
                "existing_user_id": existing_user["id"]
            }
        else:
            # Store face hash for current user
            await db.execute(
                "UPDATE users SET face_hash = ? WHERE id = ?",
                (face_hash, current_user["id"])
            )
            await db.commit()
            
            return {
                "is_duplicate": False,
                "message": "Face is unique",
                "face_hash": face_hash
            }
            
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Duplicate check failed: {str(e)}"
        )

@router.get("/verification-status")
async def get_verification_status(
    current_user: dict = Depends(get_current_user)
):
    """Get current user's verification status"""
    return {
        "user_id": current_user["id"],
        "is_face_verified": current_user.get("is_face_verified", False),
        "gender": current_user.get("gender"),
        "avatar_data": current_user.get("avatar_data"),
        "face_verified_at": current_user.get("face_verified_at")
    }
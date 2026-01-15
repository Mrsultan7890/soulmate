from fastapi import APIRouter, Depends, HTTPException, status
from routes.auth import get_current_user
from services.anti_scam_service import AntiScamService

router = APIRouter()

@router.post("/report-user")
async def report_user(
    reported_user_id: int,
    reason: str,
    evidence: dict = {},
    current_user: dict = Depends(get_current_user)
):
    """Report a user for suspicious behavior"""
    try:
        await AntiScamService.flag_user(
            reported_user_id,
            reason,
            current_user["id"],
            evidence
        )
        
        return {"message": "User reported successfully"}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to report user: {str(e)}"
        )

@router.get("/user-safety/{user_id}")
async def check_user_safety(
    user_id: int,
    current_user: dict = Depends(get_current_user)
):
    """Check if a user has been flagged"""
    try:
        is_flagged = await AntiScamService.is_user_flagged(user_id)
        flags = await AntiScamService.get_user_flags(user_id)
        
        return {
            "is_flagged": is_flagged,
            "flag_count": len(flags),
            "safety_score": max(0, 100 - (len(flags) * 20))  # 0-100 score
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to check user safety: {str(e)}"
        )
from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect
from pydantic import BaseModel
from routes.auth import get_current_user
from config.database import get_db
from services.call_signaling_service import call_manager
import json

router = APIRouter()

class CallInitiateRequest(BaseModel):
    receiver_id: int
    call_type: str  # 'video' or 'audio'

class CallActionRequest(BaseModel):
    call_id: str

@router.post("/initiate")
async def initiate_call(
    request: CallInitiateRequest,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Initiate a video/audio call"""
    try:
        # Validate call type
        if request.call_type not in ['video', 'audio']:
            raise HTTPException(status_code=400, detail="Invalid call type")
        
        # Check if receiver exists and is a match
        match = await db.fetchone("""
            SELECT * FROM matches 
            WHERE (user1_id = ? AND user2_id = ?) 
               OR (user1_id = ? AND user2_id = ?)
        """, (current_user["id"], request.receiver_id, request.receiver_id, current_user["id"]))
        
        if not match:
            raise HTTPException(status_code=403, detail="Can only call matched users")
        
        # Get receiver info
        receiver = await db.fetchone(
            "SELECT id, name FROM users WHERE id = ?",
            (request.receiver_id,)
        )
        
        if not receiver:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Initiate call through signaling manager
        result = await call_manager.initiate_call(
            caller_id=current_user["id"],
            receiver_id=request.receiver_id,
            call_type=request.call_type
        )
        
        if not result["success"]:
            raise HTTPException(status_code=400, detail=result.get("error", "Failed to initiate call"))
        
        return {
            "success": True,
            "call_id": result["call_id"],
            "receiver": {
                "id": receiver["id"],
                "name": receiver["name"]
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to initiate call: {str(e)}")

@router.post("/accept")
async def accept_call(
    request: CallActionRequest,
    current_user: dict = Depends(get_current_user)
):
    """Accept an incoming call"""
    try:
        success = await call_manager.accept_call(
            call_id=request.call_id,
            receiver_id=current_user["id"]
        )
        
        if not success:
            raise HTTPException(status_code=400, detail="Failed to accept call")
        
        return {"success": True, "message": "Call accepted"}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/reject")
async def reject_call(
    request: CallActionRequest,
    current_user: dict = Depends(get_current_user)
):
    """Reject an incoming call"""
    try:
        success = await call_manager.reject_call(
            call_id=request.call_id,
            receiver_id=current_user["id"]
        )
        
        if not success:
            raise HTTPException(status_code=400, detail="Failed to reject call")
        
        return {"success": True, "message": "Call rejected"}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/end")
async def end_call(
    request: CallActionRequest,
    current_user: dict = Depends(get_current_user)
):
    """End an active call"""
    try:
        await call_manager.end_call(
            call_id=request.call_id,
            user_id=current_user["id"]
        )
        
        return {"success": True, "message": "Call ended"}
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.websocket("/signal/{user_id}")
async def call_signaling_websocket(websocket: WebSocket, user_id: int):
    """WebSocket endpoint for WebRTC signaling"""
    await websocket.accept()
    await call_manager.connect(user_id, websocket)
    
    try:
        while True:
            data = await websocket.receive_text()
            message = json.loads(data)
            
            message_type = message.get("type")
            
            if message_type == "webrtc_signal":
                # Forward WebRTC signaling (SDP/ICE) to other user
                to_user_id = message.get("to_user_id")
                signal_data = message.get("signal")
                
                if to_user_id and signal_data:
                    await call_manager.forward_signal(
                        from_user_id=user_id,
                        to_user_id=to_user_id,
                        signal_data=signal_data
                    )
            
            elif message_type == "ping":
                await websocket.send_json({"type": "pong"})
                
    except WebSocketDisconnect:
        call_manager.disconnect(user_id)
    except Exception as e:
        print(f"WebSocket error: {e}")
        call_manager.disconnect(user_id)

@router.get("/active")
async def get_active_calls(current_user: dict = Depends(get_current_user)):
    """Get user's active calls"""
    active_calls = []
    
    for call_id, call_data in call_manager.active_calls.items():
        if call_data["caller_id"] == current_user["id"] or call_data["receiver_id"] == current_user["id"]:
            active_calls.append({
                "call_id": call_id,
                "call_type": call_data["call_type"],
                "status": call_data["status"],
                "started_at": call_data["started_at"]
            })
    
    return {"active_calls": active_calls}

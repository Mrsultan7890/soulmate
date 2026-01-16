from typing import Dict, Optional
from fastapi import WebSocket
import json
from datetime import datetime

class CallSignalingManager:
    """Manages WebRTC signaling for video/audio calls"""
    
    def __init__(self):
        # Active WebSocket connections: {user_id: websocket}
        self.connections: Dict[int, WebSocket] = {}
        
        # Active calls: {call_id: {caller_id, receiver_id, status, type}}
        self.active_calls: Dict[str, dict] = {}
        
        # Call history for analytics
        self.call_history: list = []
    
    async def connect(self, user_id: int, websocket: WebSocket):
        """Register user's WebSocket connection"""
        self.connections[user_id] = websocket
        print(f"📞 User {user_id} connected to call signaling")
    
    def disconnect(self, user_id: int):
        """Remove user's WebSocket connection"""
        if user_id in self.connections:
            del self.connections[user_id]
            print(f"📞 User {user_id} disconnected from call signaling")
    
    async def initiate_call(self, caller_id: int, receiver_id: int, call_type: str) -> dict:
        """Initiate a call from caller to receiver"""
        call_id = f"{caller_id}_{receiver_id}_{int(datetime.now().timestamp())}"
        
        # Check if receiver is online
        if receiver_id not in self.connections:
            return {
                "success": False,
                "error": "User is offline"
            }
        
        # Create call record
        self.active_calls[call_id] = {
            "caller_id": caller_id,
            "receiver_id": receiver_id,
            "call_type": call_type,  # 'video' or 'audio'
            "status": "ringing",
            "started_at": datetime.now().isoformat()
        }
        
        # Send call notification to receiver
        try:
            await self.connections[receiver_id].send_json({
                "type": "incoming_call",
                "call_id": call_id,
                "caller_id": caller_id,
                "call_type": call_type
            })
            
            return {
                "success": True,
                "call_id": call_id
            }
        except Exception as e:
            print(f"Error sending call notification: {e}")
            return {
                "success": False,
                "error": "Failed to reach user"
            }
    
    async def accept_call(self, call_id: str, receiver_id: int) -> bool:
        """Receiver accepts the call"""
        if call_id not in self.active_calls:
            return False
        
        call = self.active_calls[call_id]
        call["status"] = "active"
        call["accepted_at"] = datetime.now().isoformat()
        
        # Notify caller that call was accepted
        caller_id = call["caller_id"]
        if caller_id in self.connections:
            try:
                await self.connections[caller_id].send_json({
                    "type": "call_accepted",
                    "call_id": call_id
                })
                return True
            except:
                return False
        return False
    
    async def reject_call(self, call_id: str, receiver_id: int) -> bool:
        """Receiver rejects the call"""
        if call_id not in self.active_calls:
            return False
        
        call = self.active_calls[call_id]
        caller_id = call["caller_id"]
        
        # Notify caller
        if caller_id in self.connections:
            try:
                await self.connections[caller_id].send_json({
                    "type": "call_rejected",
                    "call_id": call_id
                })
            except:
                pass
        
        # Remove call
        del self.active_calls[call_id]
        return True
    
    async def end_call(self, call_id: str, user_id: int):
        """End an active call"""
        if call_id not in self.active_calls:
            return
        
        call = self.active_calls[call_id]
        caller_id = call["caller_id"]
        receiver_id = call["receiver_id"]
        
        # Notify the other user
        other_user_id = receiver_id if user_id == caller_id else caller_id
        
        if other_user_id in self.connections:
            try:
                await self.connections[other_user_id].send_json({
                    "type": "call_ended",
                    "call_id": call_id
                })
            except:
                pass
        
        # Save to history
        call["ended_at"] = datetime.now().isoformat()
        call["status"] = "ended"
        self.call_history.append(call)
        
        # Remove from active calls
        del self.active_calls[call_id]
    
    async def forward_signal(self, from_user_id: int, to_user_id: int, signal_data: dict):
        """Forward WebRTC signaling data (SDP/ICE) between users"""
        if to_user_id not in self.connections:
            return False
        
        try:
            await self.connections[to_user_id].send_json({
                "type": "webrtc_signal",
                "from_user_id": from_user_id,
                "signal": signal_data
            })
            return True
        except Exception as e:
            print(f"Error forwarding signal: {e}")
            return False

# Global instance
call_manager = CallSignalingManager()

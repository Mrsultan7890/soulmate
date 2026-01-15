from fastapi import WebSocket
from typing import Dict, List
import json

class ConnectionManager:
    def __init__(self):
        # Store active connections: user_id -> websocket
        self.active_connections: Dict[int, WebSocket] = {}
    
    async def connect(self, websocket: WebSocket, user_id: int):
        """Accept WebSocket connection"""
        await websocket.accept()
        self.active_connections[user_id] = websocket
        print(f"User {user_id} connected to WebSocket")
    
    def disconnect(self, user_id: int):
        """Remove WebSocket connection"""
        if user_id in self.active_connections:
            del self.active_connections[user_id]
            print(f"User {user_id} disconnected from WebSocket")
    
    async def send_personal_message(self, message: str, user_id: int):
        """Send message to specific user"""
        if user_id in self.active_connections:
            try:
                await self.active_connections[user_id].send_text(message)
            except:
                # Connection might be closed
                self.disconnect(user_id)
    
    async def send_message_to_user(self, user_id: int, message: dict):
        """Send JSON message to specific user"""
        if user_id in self.active_connections:
            try:
                await self.active_connections[user_id].send_text(json.dumps(message))
            except:
                # Connection might be closed
                self.disconnect(user_id)
    
    async def broadcast_to_match(self, match_id: int, sender_id: int, message: dict):
        """Broadcast message to all users in a match (except sender)"""
        # This would require database lookup to find match participants
        # For now, we'll implement a simple version
        for user_id, websocket in self.active_connections.items():
            if user_id != sender_id:
                try:
                    await websocket.send_text(json.dumps(message))
                except:
                    self.disconnect(user_id)
    
    def get_active_users(self) -> List[int]:
        """Get list of active user IDs"""
        return list(self.active_connections.keys())
    
    def is_user_online(self, user_id: int) -> bool:
        """Check if user is online"""
        return user_id in self.active_connections

# Global connection manager instance
manager = ConnectionManager()
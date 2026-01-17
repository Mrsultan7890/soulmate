import json
import random
from typing import Dict, List, Optional
from datetime import datetime

class GameService:
    def __init__(self):
        self.active_connections: Dict[int, List] = {}  # zone_id -> [websockets]
        self.game_sessions: Dict[int, dict] = {}  # zone_id -> game_state
        
        # Truth/Dare questions
        self.truth_questions = [
            "What's your biggest dating red flag?",
            "Who was your first crush?",
            "What's the most embarrassing thing you've done for love?",
            "Rate everyone here from 1-10 honestly",
            "What's your ideal first date?",
            "Have you ever stalked someone on social media?",
            "What's your biggest turn-off?",
            "Who would you date in this room?",
            "What's your love language?",
            "Biggest relationship mistake you've made?"
        ]
        
        self.dare_challenges = [
            "Send a flirty message to your crush",
            "Do your best pickup line on someone here",
            "Share your most embarrassing photo",
            "Sing a romantic song",
            "Dance for 30 seconds",
            "Tell a joke and make everyone laugh",
            "Compliment everyone in the room",
            "Share your phone wallpaper",
            "Do 10 pushups",
            "Act like your favorite movie character"
        ]
    
    async def create_zone(self, db, creator_id: int, zone_name: str):
        """Create new friend zone"""
        cursor = await db.execute("""
            INSERT INTO friend_zones (creator_id, zone_name, current_players)
            VALUES (?, ?, 1)
        """, (creator_id, zone_name))
        
        zone_id = cursor.lastrowid
        
        # Add creator as admin
        await db.execute("""
            INSERT INTO zone_members (zone_id, user_id, role)
            VALUES (?, ?, 'admin')
        """, (zone_id, creator_id))
        
        await db.commit()
        return zone_id
    
    async def join_zone(self, db, zone_id: int, user_id: int):
        """Join existing zone"""
        # Check if zone exists and has space
        zone = await db.fetchone("""
            SELECT current_players, max_players, status 
            FROM friend_zones WHERE id = ?
        """, (zone_id,))
        
        if not zone or zone['current_players'] >= zone['max_players']:
            return False
        
        # Check if user already in zone
        existing = await db.fetchone("""
            SELECT id FROM zone_members WHERE zone_id = ? AND user_id = ?
        """, (zone_id, user_id))
        
        if existing:
            return False
        
        # Add member
        await db.execute("""
            INSERT INTO zone_members (zone_id, user_id, role)
            VALUES (?, ?, 'member')
        """, (zone_id, user_id))
        
        # Update player count
        await db.execute("""
            UPDATE friend_zones SET current_players = current_players + 1
            WHERE id = ?
        """, (zone_id,))
        
        await db.commit()
        return True
    
    async def start_game(self, db, zone_id: int):
        """Start bottle spin game"""
        # Create game session
        cursor = await db.execute("""
            INSERT INTO game_sessions (zone_id, game_type, status)
            VALUES (?, 'truth_dare', 'active')
        """, (zone_id,))
        
        session_id = cursor.lastrowid
        
        # Initialize game state
        members = await db.fetchall("""
            SELECT u.id, u.name FROM zone_members zm
            JOIN users u ON zm.user_id = u.id
            WHERE zm.zone_id = ?
        """, (zone_id,))
        
        self.game_sessions[zone_id] = {
            'session_id': session_id,
            'players': [{'id': m['id'], 'name': m['name']} for m in members],
            'current_turn': 0,
            'bottle_angle': 0,
            'status': 'spinning'
        }
        
        await db.commit()
        return session_id
    
    def spin_bottle(self, zone_id: int):
        """Spin bottle and select player"""
        if zone_id not in self.game_sessions:
            return None
        
        game = self.game_sessions[zone_id]
        players_count = len(game['players'])
        
        # Random angle (0-360)
        angle = random.uniform(0, 360)
        
        # Calculate which player the bottle points to
        player_index = int((angle / 360) * players_count)
        selected_player = game['players'][player_index]
        
        # Update game state
        game['bottle_angle'] = angle
        game['current_turn'] = player_index
        game['status'] = 'waiting_choice'
        
        return {
            'angle': angle,
            'selected_player': selected_player,
            'truth_question': random.choice(self.truth_questions),
            'dare_challenge': random.choice(self.dare_challenges)
        }
    
    async def add_connection(self, zone_id: int, websocket):
        """Add WebSocket connection"""
        if zone_id not in self.active_connections:
            self.active_connections[zone_id] = []
        self.active_connections[zone_id].append(websocket)
    
    async def remove_connection(self, zone_id: int, websocket):
        """Remove WebSocket connection"""
        if zone_id in self.active_connections:
            if websocket in self.active_connections[zone_id]:
                self.active_connections[zone_id].remove(websocket)
    
    async def broadcast_to_zone(self, zone_id: int, message: dict):
        """Broadcast message to all zone members"""
        if zone_id in self.active_connections:
            for websocket in self.active_connections[zone_id]:
                try:
                    await websocket.send_text(json.dumps(message))
                except:
                    pass

# Global instance
game_service = GameService()
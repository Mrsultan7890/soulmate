from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect
from pydantic import BaseModel
import json

from config.database import get_db
from routes.auth import get_current_user
from services.game_service import game_service

router = APIRouter()

class CreateZoneRequest(BaseModel):
    zone_name: str

class JoinZoneRequest(BaseModel):
    zone_id: int

@router.post("/create-zone")
async def create_zone(
    request: CreateZoneRequest,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Create new Friend Zone"""
    # Check if user already has active zone
    existing = await db.fetchone("""
        SELECT id FROM friend_zones 
        WHERE creator_id = ? AND status = 'waiting'
    """, (current_user['id'],))
    
    if existing:
        raise HTTPException(400, "You already have an active zone")
    
    zone_id = await game_service.create_zone(
        db, current_user['id'], request.zone_name
    )
    
    return {
        "success": True,
        "zone_id": zone_id,
        "message": "Friend Zone created successfully!"
    }

@router.post("/join-zone")
async def join_zone(
    request: JoinZoneRequest,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Join existing Friend Zone"""
    success = await game_service.join_zone(
        db, request.zone_id, current_user['id']
    )
    
    if not success:
        raise HTTPException(400, "Cannot join zone (full or already joined)")
    
    # Broadcast new member joined
    await game_service.broadcast_to_zone(request.zone_id, {
        "type": "member_joined",
        "user": {"id": current_user['id'], "name": current_user['name']}
    })
    
    return {"success": True, "message": "Joined zone successfully!"}

@router.get("/my-zones")
async def get_my_zones(
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Get user's zones"""
    zones = await db.fetchall("""
        SELECT fz.*, zm.role FROM friend_zones fz
        JOIN zone_members zm ON fz.id = zm.zone_id
        WHERE zm.user_id = ? AND fz.status != 'ended'
        ORDER BY fz.created_at DESC
    """, (current_user['id'],))
    
    return {"zones": [dict(zone) for zone in zones]}

@router.get("/zone/{zone_id}")
async def get_zone_details(
    zone_id: int,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Get zone details and members"""
    # Check if user is member
    member = await db.fetchone("""
        SELECT role FROM zone_members 
        WHERE zone_id = ? AND user_id = ?
    """, (zone_id, current_user['id']))
    
    if not member:
        raise HTTPException(403, "Not a member of this zone")
    
    # Get zone info
    zone = await db.fetchone("""
        SELECT * FROM friend_zones WHERE id = ?
    """, (zone_id,))
    
    # Get members
    members = await db.fetchall("""
        SELECT u.id, u.name, u.age, zm.role FROM zone_members zm
        JOIN users u ON zm.user_id = u.id
        WHERE zm.zone_id = ?
    """, (zone_id,))
    
    return {
        "zone": dict(zone),
        "members": [dict(member) for member in members],
        "is_admin": member['role'] == 'admin'
    }

@router.post("/invite-user")
async def invite_user_to_zone(
    request: dict,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Invite user to Friend Zone"""
    zone_id = request.get('zone_id')
    invited_user_id = request.get('user_id')
    
    # Check if user is admin of zone
    member = await db.fetchone("""
        SELECT role FROM zone_members 
        WHERE zone_id = ? AND user_id = ?
    """, (zone_id, current_user['id']))
    
    if not member or member['role'] != 'admin':
        raise HTTPException(403, "Only admin can invite users")
    
    # Check zone capacity
    zone = await db.fetchone("""
        SELECT current_players, max_players FROM friend_zones WHERE id = ?
    """, (zone_id,))
    
    if zone['current_players'] >= zone['max_players']:
        raise HTTPException(400, "Zone is full")
    
    # Send FCM invitation
    try:
        from services.fcm_notification_service import fcm_service
        invited_user = await db.fetchone("""
            SELECT fcm_token, name FROM users WHERE id = ?
        """, (invited_user_id,))
        
        zone_info = await db.fetchone("""
            SELECT zone_name FROM friend_zones WHERE id = ?
        """, (zone_id,))
        
        if invited_user and invited_user['fcm_token']:
            await fcm_service.send_notification(
                fcm_token=invited_user['fcm_token'],
                title="🎮 Friend Zone Invitation!",
                body=f"{current_user['name']} invited you to join '{zone_info['zone_name']}' game zone!",
                data={
                    "type": "zone_invitation",
                    "zone_id": str(zone_id),
                    "zone_name": zone_info['zone_name'],
                    "inviter_name": current_user['name']
                }
            )
    except Exception as e:
        print(f"Invitation notification failed: {e}")
    
    return {
        "success": True,
        "message": f"Invitation sent to {invited_user['name'] if invited_user else 'user'}!"
    }
async def start_game(
    zone_id: int,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Start bottle spin game (admin only)"""
    # Check if user is admin
    member = await db.fetchone("""
        SELECT role FROM zone_members 
        WHERE zone_id = ? AND user_id = ?
    """, (zone_id, current_user['id']))
    
    if not member or member['role'] != 'admin':
        raise HTTPException(403, "Only admin can start game")
    
    session_id = await game_service.start_game(db, zone_id)
    
    # Broadcast game started
    await game_service.broadcast_to_zone(zone_id, {
        "type": "game_started",
        "session_id": session_id
    })
    
    return {"success": True, "session_id": session_id}

@router.post("/zone/{zone_id}/spin-bottle")
async def spin_bottle(
    zone_id: int,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Spin the bottle"""
    result = game_service.spin_bottle(zone_id)
    
    if not result:
        raise HTTPException(400, "No active game in this zone")
    
    # Broadcast spin result
    await game_service.broadcast_to_zone(zone_id, {
        "type": "bottle_spun",
        "result": result
    })
    
    return result

@router.post("/zone/{zone_id}/ask-question")
async def ask_question(
    zone_id: int,
    request: dict,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Ask a custom question"""
    question = request.get('question', '').strip()
    question_type = request.get('type', 'text')  # text or voice
    
    if not question:
        raise HTTPException(400, "Question cannot be empty")
    
    result = await game_service.ask_question(
        zone_id, current_user['id'], question, question_type
    )
    
    if not result:
        raise HTTPException(400, "Cannot ask question right now")
    
    # Broadcast question to all players
    await game_service.broadcast_to_zone(zone_id, {
        "type": "question_asked",
        "result": result
    })
    
    return result

@router.websocket("/zone/{zone_id}/ws")
async def websocket_endpoint(websocket: WebSocket, zone_id: int):
    """WebSocket connection for real-time game updates"""
    await websocket.accept()
    await game_service.add_connection(zone_id, websocket)
    
    try:
        while True:
            data = await websocket.receive_text()
            message = json.loads(data)
            
            # Handle different message types
            if message.get("type") == "chat_message":
                # Broadcast chat message to all zone members
                await game_service.broadcast_to_zone(zone_id, {
                    "type": "chat_message",
                    "message": message.get("message"),
                    "sender": message.get("sender"),
                    "timestamp": message.get("timestamp")
                })
            elif message.get("type") == "answer_given":
                # Broadcast answer to question
                await game_service.broadcast_to_zone(zone_id, {
                    "type": "answer_given",
                    "answer": message.get("answer"),
                    "answerer": message.get("answerer")
                })
            
    except WebSocketDisconnect:
        await game_service.remove_connection(zone_id, websocket)
import aiosqlite
from datetime import datetime

async def init_game_tables(db):
    """Initialize game-related tables"""
    
    # Friend zones table
    await db.execute("""
        CREATE TABLE IF NOT EXISTS friend_zones (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            creator_id INTEGER NOT NULL,
            zone_name TEXT NOT NULL,
            max_players INTEGER DEFAULT 6,
            current_players INTEGER DEFAULT 1,
            status TEXT DEFAULT 'waiting',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (creator_id) REFERENCES users (id)
        )
    """)
    
    # Zone members table
    await db.execute("""
        CREATE TABLE IF NOT EXISTS zone_members (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            zone_id INTEGER NOT NULL,
            user_id INTEGER NOT NULL,
            role TEXT DEFAULT 'member',
            joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (zone_id) REFERENCES friend_zones (id),
            FOREIGN KEY (user_id) REFERENCES users (id),
            UNIQUE(zone_id, user_id)
        )
    """)
    
    # Game sessions table
    await db.execute("""
        CREATE TABLE IF NOT EXISTS game_sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            zone_id INTEGER NOT NULL,
            game_type TEXT DEFAULT 'truth_dare',
            current_player INTEGER,
            bottle_angle REAL DEFAULT 0,
            status TEXT DEFAULT 'active',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (zone_id) REFERENCES friend_zones (id)
        )
    """)
    
    # Game moves table
    await db.execute("""
        CREATE TABLE IF NOT EXISTS game_moves (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            session_id INTEGER NOT NULL,
            player_id INTEGER NOT NULL,
            move_type TEXT NOT NULL,
            move_data TEXT,
            timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (session_id) REFERENCES game_sessions (id),
            FOREIGN KEY (player_id) REFERENCES users (id)
        )
    """)
    
    # Zone invitations table
    await db.execute("""
        CREATE TABLE IF NOT EXISTS zone_invitations (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            zone_id INTEGER NOT NULL,
            invited_user_id INTEGER NOT NULL,
            inviter_id INTEGER NOT NULL,
            status TEXT DEFAULT 'pending',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (zone_id) REFERENCES friend_zones (id),
            FOREIGN KEY (invited_user_id) REFERENCES users (id),
            FOREIGN KEY (inviter_id) REFERENCES users (id)
        )
    """)
    
    await db.commit()
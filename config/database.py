import sqlite3
import asyncio
from typing import Optional
import os
from .settings import settings

class Database:
    def __init__(self):
        self.db_path = "heartlink.db"
        self.conn = None
    
    async def connect(self):
        """Connect to SQLite database"""
        try:
            self.conn = sqlite3.connect(self.db_path, check_same_thread=False)
            self.conn.row_factory = sqlite3.Row
            print("✅ Connected to SQLite database")
            return self.conn
        except Exception as e:
            print(f"❌ Database connection error: {e}")
            raise
    
    async def execute(self, query: str, params: tuple = ()):
        """Execute SQL query"""
        if not self.conn:
            await self.connect()
        
        try:
            cursor = self.conn.execute(query, params)
            return cursor
        except Exception as e:
            print(f"❌ Query execution error: {e}")
            raise
    
    async def fetchone(self, query: str, params: tuple = ()):
        """Fetch single row"""
        cursor = await self.execute(query, params)
        return cursor.fetchone()
    
    async def fetchall(self, query: str, params: tuple = ()):
        """Fetch all rows"""
        cursor = await self.execute(query, params)
        return cursor.fetchall()
    
    async def commit(self):
        """Commit transaction"""
        if self.conn:
            self.conn.commit()

# Global database instance
db = Database()

async def init_db():
    """Initialize database tables"""
    await db.connect()
    
    # Users table
    await db.execute("""
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            name TEXT NOT NULL,
            age INTEGER,
            bio TEXT,
            location TEXT,
            latitude REAL,
            longitude REAL,
            gps_updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            interests TEXT, -- JSON array of interests
            relationship_intent TEXT, -- "serious", "casual", "friends"
            profile_images TEXT, -- JSON array of Telegram file IDs
            preferences TEXT, -- JSON preferences
            is_verified BOOLEAN DEFAULT FALSE,
            is_premium BOOLEAN DEFAULT FALSE,
            flag_count INTEGER DEFAULT 0,
            is_blocked BOOLEAN DEFAULT FALSE,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
        )
    """)
    
    # Swipes table
    await db.execute("""
        CREATE TABLE IF NOT EXISTS swipes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            swiper_id INTEGER NOT NULL,
            swiped_id INTEGER NOT NULL,
            is_like BOOLEAN NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (swiper_id) REFERENCES users (id),
            FOREIGN KEY (swiped_id) REFERENCES users (id),
            UNIQUE(swiper_id, swiped_id)
        )
    """)
    
    # Matches table
    await db.execute("""
        CREATE TABLE IF NOT EXISTS matches (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user1_id INTEGER NOT NULL,
            user2_id INTEGER NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user1_id) REFERENCES users (id),
            FOREIGN KEY (user2_id) REFERENCES users (id),
            UNIQUE(user1_id, user2_id)
        )
    """)
    
    # Messages table
    await db.execute("""
        CREATE TABLE IF NOT EXISTS messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            match_id INTEGER NOT NULL,
            sender_id INTEGER NOT NULL,
            content TEXT NOT NULL,
            message_type TEXT DEFAULT 'text', -- text, image, emoji
            is_read BOOLEAN DEFAULT FALSE,
            is_flagged BOOLEAN DEFAULT FALSE,
            risk_score INTEGER DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (match_id) REFERENCES matches (id),
            FOREIGN KEY (sender_id) REFERENCES users (id)
        )
    """)
    
    # User flags table
    await db.execute("""
        CREATE TABLE IF NOT EXISTS user_flags (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL,
            reason TEXT NOT NULL,
            reported_by INTEGER,
            evidence TEXT, -- JSON evidence
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (user_id) REFERENCES users (id),
            FOREIGN KEY (reported_by) REFERENCES users (id)
        )
    """)
    
    await db.commit()
    print("✅ Database tables initialized")

async def get_db():
    """Dependency to get database connection"""
    return db
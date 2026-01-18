from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import uvicorn

from routes import auth, users, matches, chat, safety, enhanced_chat, safety_tips, fcm, gender_verification, calls, profile_features, games, feed
from routes import settings as user_settings
from config.database import init_db
from config.settings import settings

# Initialize FastAPI app
app = FastAPI(
    title="HeartLink API",
    description="Dating App Backend with Turso DB & Telegram Integration",
    version="1.0.0"
)

# CORS middleware for Flutter app
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:*",
        "http://127.0.0.1:*",
        "https://your-production-domain.com",  # Add your production domain
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api/auth", tags=["Authentication"])
app.include_router(users.router, prefix="/api/users", tags=["Users"])
app.include_router(matches.router, prefix="/api/matches", tags=["Matches"])
app.include_router(chat.router, prefix="/api/chat", tags=["Chat"])
app.include_router(enhanced_chat.router, prefix="/api/enhanced-chat", tags=["Enhanced Chat"])
app.include_router(safety.router, prefix="/api/safety", tags=["Safety"])
app.include_router(safety_tips.router, prefix="/api/safety-tips", tags=["Safety Tips"])
app.include_router(gender_verification.router, prefix="/api/verification", tags=["Gender Verification"])
app.include_router(calls.router, prefix="/api/calls", tags=["Video/Audio Calls"])
app.include_router(profile_features.router, prefix="/api/profile", tags=["Profile Features"])
app.include_router(games.router, prefix="/api/games", tags=["Friend Zone Games"])
app.include_router(feed.router, tags=["Feed"])
app.include_router(user_settings.router, tags=["Settings"])

app.include_router(fcm.router, prefix="/api/users", tags=["FCM"])

# WebSocket route (no prefix for WebSocket)
from routes.chat import websocket_endpoint
app.websocket("/api/chat/ws/{user_id}")(websocket_endpoint)

@app.on_event("startup")
async def startup_event():
    """Initialize database on startup"""
    await init_db()
    print("🚀 HeartLink API Started!")

@app.get("/")
async def root():
    return {
        "message": "💕 HeartLink API",
        "version": "1.0.0",
        "status": "active"
    }

@app.get("/health")
async def health_check():
    return {"status": "healthy", "service": "heartlink-api"}

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host=settings.HOST,
        port=settings.PORT,
        reload=settings.DEBUG
    )
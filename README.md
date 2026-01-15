# HeartLink Dating App Backend

## 🚀 Setup Instructions

### 1. Install Dependencies
```bash
cd heartlink
pip install -r requirements.txt
```

### 2. Environment Variables
Create `.env` file:
```env
# Turso Database
TURSO_DATABASE_URL=libsql://your-database.turso.io
TURSO_AUTH_TOKEN=your-auth-token

# JWT Secret
SECRET_KEY=your-super-secret-jwt-key

# Telegram Bot (for image storage)
TELEGRAM_BOT_TOKEN=your-bot-token
TELEGRAM_CHAT_ID=your-chat-id
```

### 3. Get Turso Database (FREE)
```bash
# Install Turso CLI
curl -sSfL https://get.tur.so/install.sh | bash

# Create database
turso db create heartlink

# Get database URL
turso db show heartlink

# Create auth token
turso db tokens create heartlink
```

### 4. Setup Telegram Bot (FREE)
1. Message @BotFather on Telegram
2. Create new bot: `/newbot`
3. Get bot token
4. Create private channel for image storage
5. Add bot to channel as admin
6. Get chat ID

### 5. Run Server
```bash
python main.py
# or
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## 📱 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user

### Users
- `GET /api/users/profile` - Get profile
- `PUT /api/users/profile` - Update profile
- `POST /api/users/upload-image` - Upload profile image
- `GET /api/users/discover` - Get users to swipe

### Matches
- `POST /api/matches/swipe` - Swipe on user
- `GET /api/matches/` - Get all matches
- `DELETE /api/matches/{id}` - Unmatch user

### Chat
- `GET /api/chat/{match_id}/messages` - Get messages
- `POST /api/chat/{match_id}/messages` - Send message
- `WS /api/chat/ws/{user_id}` - WebSocket connection

## 🏗️ Architecture

```
heartlink/
├── main.py              # FastAPI app
├── config/
│   ├── database.py      # Turso DB connection
│   └── settings.py      # Environment settings
├── models/
│   └── schemas.py       # Pydantic models
├── routes/
│   ├── auth.py         # Authentication
│   ├── users.py        # User management
│   ├── matches.py      # Swiping & matching
│   └── chat.py         # Messaging
├── services/
│   ├── telegram_service.py    # Image storage
│   ├── websocket_manager.py   # Real-time chat
│   └── notification_service.py # Notifications
└── utils/              # Helper functions
```

## 💰 Cost: 100% FREE
- **Turso**: 500MB free
- **Telegram**: Free bot & storage
- **Render**: Free hosting
- **Total**: ₹0

## 🔧 Features
- ✅ User registration/login
- ✅ Profile management
- ✅ Image upload via Telegram
- ✅ Swipe & match system
- ✅ Real-time chat
- ✅ WebSocket support
- ✅ JWT authentication
- ✅ Modular architecture# heartlink
# soulmate

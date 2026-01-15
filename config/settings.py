from pydantic_settings import BaseSettings
from dotenv import load_dotenv
import os

load_dotenv()

class Settings(BaseSettings):
    # Database
    TURSO_DATABASE_URL: str = os.getenv("TURSO_DATABASE_URL", "libsql://your-db.turso.io")
    TURSO_AUTH_TOKEN: str = os.getenv("TURSO_AUTH_TOKEN", "your-auth-token")
    
    # JWT
    SECRET_KEY: str = os.getenv("SECRET_KEY", "heartlink-secret-key-change-in-production")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "10080"))
    
    # Telegram Bot
    TELEGRAM_BOT_TOKEN: str = os.getenv("TELEGRAM_BOT_TOKEN", "")
    TELEGRAM_CHAT_ID: str = os.getenv("TELEGRAM_CHAT_ID", "@storagecat")
    
    # App Settings
    APP_NAME: str = "HeartLink"
    DEBUG: bool = os.getenv("DEBUG", "True").lower() == "true"
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8000"))
    
    # File Upload
    MAX_FILE_SIZE: int = 5 * 1024 * 1024  # 5MB
    ALLOWED_IMAGE_TYPES: list = ["image/jpeg", "image/png", "image/webp"]
    
    class Config:
        env_file = ".env"

settings = Settings()
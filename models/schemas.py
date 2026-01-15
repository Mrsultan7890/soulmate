from pydantic import BaseModel, EmailStr, validator
from typing import Optional, List
from datetime import datetime
import json

class UserBase(BaseModel):
    email: EmailStr
    name: str
    age: Optional[int] = None
    bio: Optional[str] = None
    location: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    interests: List[str] = []
    relationship_intent: Optional[str] = None  # "serious", "casual", "friends"

class UserCreate(UserBase):
    password: str
    
    @validator('password')
    def validate_password(cls, v):
        if len(v) < 6:
            raise ValueError('Password must be at least 6 characters')
        return v
    
    @validator('age')
    def validate_age(cls, v):
        if v and (v < 18 or v > 100):
            raise ValueError('Age must be between 18 and 100')
        return v

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserProfile(UserBase):
    id: int
    profile_images: List[str] = []
    preferences: dict = {}
    is_verified: bool = False
    is_premium: bool = False
    created_at: datetime
    
    class Config:
        from_attributes = True

class UserUpdate(BaseModel):
    name: Optional[str] = None
    age: Optional[int] = None
    bio: Optional[str] = None
    location: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    interests: Optional[List[str]] = None
    relationship_intent: Optional[str] = None
    preferences: Optional[dict] = None

class SwipeCreate(BaseModel):
    swiped_user_id: int
    is_like: bool

class SwipeResponse(BaseModel):
    is_match: bool
    match_id: Optional[int] = None

class Match(BaseModel):
    id: int
    user1_id: int
    user2_id: int
    user1_profile: UserProfile
    user2_profile: UserProfile
    created_at: datetime
    last_message: Optional[str] = None
    last_message_time: Optional[datetime] = None

class MessageCreate(BaseModel):
    match_id: int
    content: str
    message_type: str = "text"

class Message(BaseModel):
    id: int
    match_id: int
    sender_id: int
    content: str
    message_type: str
    is_read: bool
    created_at: datetime
    sender_name: str

class Token(BaseModel):
    access_token: str
    token_type: str
    user: UserProfile

class TokenData(BaseModel):
    email: Optional[str] = None

class ImageUpload(BaseModel):
    telegram_file_id: str
    caption: Optional[str] = None
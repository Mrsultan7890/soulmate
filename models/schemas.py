from pydantic import BaseModel, EmailStr, Field
from typing import Optional, List
from datetime import datetime

class UserCreate(BaseModel):
    name: str
    email: EmailStr
    password: str
    age: int
    gender: Optional[str] = None
    bio: Optional[str] = None
    interests: Optional[List[str]] = []
    location: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    relationship_intent: Optional[str] = None
    profile_images: Optional[List[str]] = []
    preferences: Optional[dict] = {}

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"

class UserProfile(BaseModel):
    id: int
    name: str
    email: str
    age: int
    gender: Optional[str] = None
    bio: Optional[str] = None
    interests: Optional[List[str]] = []
    avatar_data: Optional[dict] = {}
    is_face_verified: bool = False
    created_at: Optional[str] = None
    location: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    relationship_intent: Optional[str] = None
    profile_images: Optional[List[str]] = []
    preferences: Optional[dict] = {}
    is_verified: bool = False
    is_premium: bool = False
    
    class Config:
        from_attributes = True

class UserUpdate(BaseModel):
    name: Optional[str] = None
    bio: Optional[str] = None
    age: Optional[int] = None
    interests: Optional[List[str]] = None
    gender: Optional[str] = None
    location: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    job_title: Optional[str] = None
    company: Optional[str] = None
    education_level: Optional[str] = None
    education_details: Optional[str] = None
    height: Optional[int] = None
    body_type: Optional[str] = None
    smoking: Optional[str] = None
    drinking: Optional[str] = None
    diet_preference: Optional[str] = None
    religion: Optional[str] = None
    caste: Optional[str] = None
    mother_tongue: Optional[str] = None
    gym_frequency: Optional[str] = None
    travel_frequency: Optional[str] = None
    relationship_intent: Optional[str] = None
    preferences: Optional[dict] = None
    profile_prompts: Optional[dict] = None

class ImageUpload(BaseModel):
    telegram_file_id: str  # Telegram file_id or base64 image
    image_type: Optional[str] = "profile"  # profile, verification, etc

class SwipeCreate(BaseModel):
    target_user_id: int
    action: str  # 'like' or 'pass'

class SwipeResponse(BaseModel):
    is_match: bool
    match_id: Optional[int] = None
    message: str

class Match(BaseModel):
    id: int
    user1_id: int
    user2_id: int
    created_at: str
    user1_profile: Optional[UserProfile] = None
    user2_profile: Optional[UserProfile] = None
    
    class Config:
        from_attributes = True

class MessageCreate(BaseModel):
    match_id: int
    content: str
    message_type: Optional[str] = "text"  # text, image, etc

class Message(BaseModel):
    id: int
    match_id: int
    sender_id: int
    content: str
    message_type: str
    created_at: str
    is_read: bool = False
    
    class Config:
        from_attributes = True

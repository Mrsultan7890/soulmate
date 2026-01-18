from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from datetime import datetime, timedelta
from jose import JWTError, jwt
from passlib.context import CryptContext
import json

from models.schemas import UserCreate, UserLogin, Token, UserProfile
from config.database import get_db
from config.settings import settings

router = APIRouter()

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="api/auth/login")

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: timedelta = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt

def safe_json_loads(value, default):
    """Safely parse JSON with fallback"""
    if not value:
        return default
    try:
        return json.loads(value)
    except:
        return default

async def get_current_user(token: str = Depends(oauth2_scheme), db = Depends(get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception
    
    user = await db.fetchone("SELECT * FROM users WHERE email = ?", (email,))
    if user is None:
        raise credentials_exception
    
    return dict(user)

@router.post("/register", response_model=Token)
async def register(user: UserCreate, db = Depends(get_db)):
    # Check if user exists
    existing_user = await db.fetchone("SELECT id FROM users WHERE email = ?", (user.email,))
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered. Please login instead."
        )
    
    # Validate email format
    import re
    email_pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    if not re.match(email_pattern, user.email):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid email format"
        )
    
    # Validate password length
    if len(user.password) < 6:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Password must be at least 6 characters"
        )
    
    # Hash password
    hashed_password = get_password_hash(user.password)
    
    # Create user
    await db.execute("""
        INSERT INTO users (email, password_hash, name, age, bio, location, latitude, longitude, interests, relationship_intent, profile_images, preferences)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    """, (
        user.email,
        hashed_password,
        user.name,
        user.age,
        user.bio,
        user.location,
        user.latitude,
        user.longitude,
        json.dumps(user.interests),
        user.relationship_intent,
        json.dumps([]),  # Empty images array
        json.dumps({})   # Empty preferences
    ))
    await db.commit()
    
    # Get created user
    created_user = await db.fetchone("SELECT * FROM users WHERE email = ?", (user.email,))
    user_dict = dict(created_user)
    
    # Create access token
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.email}, expires_delta=access_token_expires
    )
    
    # Format user profile
    user_profile = UserProfile(
        id=user_dict["id"],
        email=user_dict["email"],
        name=user_dict["name"],
        age=user_dict["age"],
        bio=user_dict["bio"],
        location=user_dict["location"],
        latitude=user_dict.get("latitude"),
        longitude=user_dict.get("longitude"),
        interests=safe_json_loads(user_dict.get("interests"), []),
        relationship_intent=user_dict.get("relationship_intent"),
        profile_images=safe_json_loads(user_dict.get("profile_images"), []),
        preferences=safe_json_loads(user_dict.get("preferences"), {}),
        avatar_data=safe_json_loads(user_dict.get("avatar_data"), {}),
        is_verified=user_dict.get("is_verified", False),
        is_premium=user_dict.get("is_premium", False),
        is_face_verified=user_dict.get("is_face_verified", False),
        created_at=user_dict.get("created_at")
    )
    
    return Token(
        access_token=access_token,
        token_type="bearer",
        user=user_profile
    )

@router.post("/login")
async def login(user_login: UserLogin, db = Depends(get_db)):
    # Get user
    user = await db.fetchone("SELECT * FROM users WHERE email = ?", (user_login.email,))
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Verify password
    if not verify_password(user_login.password, user["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    user_dict = dict(user)
    
    # Send welcome notification
    try:
        from services.fcm_notification_service import FCMNotificationService
        fcm_service = FCMNotificationService()
        
        # Get user's FCM token from database
        fcm_token = user_dict.get("fcm_token")
        if fcm_token:
            await fcm_service.send_notification(
                fcm_token=fcm_token,
                title="Welcome back! 👋",
                body=f"Hi {user_dict['name']}, you're successfully logged in to HeartLink!",
                data={"type": "welcome", "timestamp": str(datetime.utcnow())}
            )
        else:
            print("No FCM token found for user - will update from frontend")
            # Update FCM token immediately after login response
            from services.fcm_notification_service import fcm_service as global_fcm
            # Store user info for delayed notification
            global_fcm.pending_welcome_notifications = getattr(global_fcm, 'pending_welcome_notifications', {})
            global_fcm.pending_welcome_notifications[user_dict['id']] = {
                'name': user_dict['name'],
                'timestamp': str(datetime.utcnow())
            }
    except Exception as e:
        print(f"Welcome notification failed: {e}")
    
    # Create access token
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user_dict["email"]}, expires_delta=access_token_expires
    )
    
    # Format user profile
    user_profile = UserProfile(
        id=user_dict["id"],
        email=user_dict["email"],
        name=user_dict["name"],
        age=user_dict["age"],
        bio=user_dict["bio"],
        location=user_dict["location"],
        latitude=user_dict.get("latitude"),
        longitude=user_dict.get("longitude"),
        interests=safe_json_loads(user_dict.get("interests"), []),
        relationship_intent=user_dict.get("relationship_intent"),
        profile_images=safe_json_loads(user_dict.get("profile_images"), []),
        preferences=safe_json_loads(user_dict.get("preferences"), {}),
        avatar_data=safe_json_loads(user_dict.get("avatar_data"), {}),
        is_verified=user_dict.get("is_verified", False),
        is_premium=user_dict.get("is_premium", False),
        is_face_verified=user_dict.get("is_face_verified", False),
        created_at=user_dict.get("created_at")
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": user_dict["id"],
            "email": user_dict["email"],
            "name": user_dict["name"],
            "age": user_dict.get("age"),
            "gender": user_dict.get("gender"),
            "bio": user_dict.get("bio"),
            "location": user_dict.get("location"),
            "latitude": user_dict.get("latitude"),
            "longitude": user_dict.get("longitude"),
            "interests": safe_json_loads(user_dict.get("interests"), []),
            "relationship_intent": user_dict.get("relationship_intent"),
            "profile_images": safe_json_loads(user_dict.get("profile_images"), []),
            "preferences": safe_json_loads(user_dict.get("preferences"), {}),
            "is_verified": bool(user_dict.get("is_verified", 0)),
            "is_premium": bool(user_dict.get("is_premium", 0)),
            "created_at": user_dict.get("created_at")
        }
    }

@router.get("/me")
async def get_current_user_profile(current_user: dict = Depends(get_current_user)):
    from services.telegram_service import get_image_url
    
    # Convert file_ids to URLs
    profile_images = safe_json_loads(current_user.get("profile_images"), [])
    image_urls = []
    for file_id in profile_images:
        try:
            url = await get_image_url(file_id)
            image_urls.append(url)
        except:
            image_urls.append("https://via.placeholder.com/400x400/FF6B6B/FFFFFF?text=HeartLink")
    
    return {
        "id": current_user["id"],
        "email": current_user["email"],
        "name": current_user["name"],
        "age": current_user.get("age"),
        "gender": current_user.get("gender"),
        "bio": current_user.get("bio"),
        "location": current_user.get("location"),
        "latitude": current_user.get("latitude"),
        "longitude": current_user.get("longitude"),
        "interests": safe_json_loads(current_user.get("interests"), []),
        "relationship_intent": current_user.get("relationship_intent"),
        "profile_images": image_urls,
        "preferences": safe_json_loads(current_user.get("preferences"), {}),
        "is_verified": bool(current_user.get("is_verified", 0)),
        "is_premium": bool(current_user.get("is_premium", 0)),
        "created_at": current_user.get("created_at")
    }

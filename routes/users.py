from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional
import json

from models.schemas import UserProfile, UserUpdate, ImageUpload
from routes.auth import get_current_user
from config.database import get_db
from services.telegram_service import upload_image_to_telegram
from services.location_service import LocationService
from services.matching_service import MatchingService
from services.photo_privacy_service import PhotoPrivacyService
from services.anti_scam_service import AntiScamService

router = APIRouter()

@router.get("/profile", response_model=UserProfile)
async def get_profile(current_user: dict = Depends(get_current_user)):
    """Get current user profile"""
    return UserProfile(
        id=current_user["id"],
        email=current_user["email"],
        name=current_user["name"],
        age=current_user["age"],
        bio=current_user["bio"],
        location=current_user["location"],
        latitude=current_user.get("latitude"),
        longitude=current_user.get("longitude"),
        interests=json.loads(current_user.get("interests", "[]")) if current_user.get("interests") else [],
        relationship_intent=current_user.get("relationship_intent"),
        profile_images=json.loads(current_user["profile_images"]),
        preferences=json.loads(current_user["preferences"]),
        is_verified=current_user["is_verified"],
        is_premium=current_user["is_premium"],
        created_at=current_user["created_at"]
    )

@router.put("/profile", response_model=UserProfile)
async def update_profile(
    profile_update: UserUpdate,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Update user profile"""
    update_fields = []
    update_values = []
    
    if profile_update.name is not None:
        update_fields.append("name = ?")
        update_values.append(profile_update.name)
    
    if profile_update.age is not None:
        update_fields.append("age = ?")
        update_values.append(profile_update.age)
    
    if profile_update.bio is not None:
        update_fields.append("bio = ?")
        update_values.append(profile_update.bio)
    
    if profile_update.location is not None:
        update_fields.append("location = ?")
        update_values.append(profile_update.location)
    
    if profile_update.latitude is not None:
        update_fields.append("latitude = ?")
        update_values.append(profile_update.latitude)
    
    if profile_update.longitude is not None:
        update_fields.append("longitude = ?")
        update_values.append(profile_update.longitude)
    
    if profile_update.interests is not None:
        update_fields.append("interests = ?")
        update_values.append(json.dumps(profile_update.interests))
    
    if profile_update.relationship_intent is not None:
        update_fields.append("relationship_intent = ?")
        update_values.append(profile_update.relationship_intent)
    
    if profile_update.preferences is not None:
        update_fields.append("preferences = ?")
        update_values.append(json.dumps(profile_update.preferences))
    
    if update_fields:
        update_fields.append("updated_at = CURRENT_TIMESTAMP")
        update_values.append(current_user["id"])
        
        query = f"UPDATE users SET {', '.join(update_fields)} WHERE id = ?"
        await db.execute(query, tuple(update_values))
        await db.commit()
    
    # Get updated user
    updated_user = await db.fetchone("SELECT * FROM users WHERE id = ?", (current_user["id"],))
    user_dict = dict(updated_user)
    
    return UserProfile(
        id=user_dict["id"],
        email=user_dict["email"],
        name=user_dict["name"],
        age=user_dict["age"],
        bio=user_dict["bio"],
        location=user_dict["location"],
        latitude=user_dict.get("latitude"),
        longitude=user_dict.get("longitude"),
        interests=json.loads(user_dict.get("interests", "[]")) if user_dict.get("interests") else [],
        relationship_intent=user_dict.get("relationship_intent"),
        profile_images=json.loads(user_dict["profile_images"]),
        preferences=json.loads(user_dict["preferences"]),
        is_verified=user_dict["is_verified"],
        is_premium=user_dict["is_premium"],
        created_at=user_dict["created_at"]
    )

@router.post("/upload-image")
async def upload_profile_image(
    image_data: ImageUpload,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Add profile image via base64 or Telegram file ID"""
    try:
        # Get current images
        current_images = json.loads(current_user["profile_images"])
        
        # Add new image (max 6 images)
        if len(current_images) >= 6:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Maximum 6 images allowed"
            )
        
        # Check if it's base64 or file_id
        file_id = image_data.telegram_file_id
        
        # If it looks like base64, upload to Telegram
        if len(file_id) > 100:  # Base64 is much longer than file_id
            from services.telegram_service import upload_image_to_telegram
            file_id = await upload_image_to_telegram(file_id, is_base64=True)
        
        current_images.append(file_id)
        
        # Update database
        await db.execute(
            "UPDATE users SET profile_images = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
            (json.dumps(current_images), current_user["id"])
        )
        await db.commit()
        
        return {
            "message": "Image uploaded successfully",
            "image_count": len(current_images),
            "file_id": file_id
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to upload image: {str(e)}"
        )

@router.delete("/image/{image_index}")
async def delete_profile_image(
    image_index: int,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Delete profile image by index"""
    try:
        current_images = json.loads(current_user["profile_images"])
        
        if image_index < 0 or image_index >= len(current_images):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid image index"
            )
        
        # Remove image
        removed_image = current_images.pop(image_index)
        
        # Update database
        await db.execute(
            "UPDATE users SET profile_images = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
            (json.dumps(current_images), current_user["id"])
        )
        await db.commit()
        
        return {
            "message": "Image deleted successfully",
            "removed_file_id": removed_image,
            "remaining_count": len(current_images)
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to delete image: {str(e)}"
        )

@router.get("/discover")
async def discover_users(
    limit: int = Query(10, le=50),
    min_age: Optional[int] = Query(None, ge=18, le=100),
    max_age: Optional[int] = Query(None, ge=18, le=100),
    max_distance_km: Optional[float] = Query(None, ge=0.1, le=100),
    relationship_intent: Optional[str] = Query(None),
    required_interests: Optional[str] = Query(None),
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Advanced user discovery with filtering"""
    try:
        filters = {}
        
        if min_age:
            filters['min_age'] = min_age
        if max_age:
            filters['max_age'] = max_age
        if max_distance_km:
            filters['max_distance_km'] = max_distance_km
        if relationship_intent:
            filters['relationship_intent'] = relationship_intent
        if required_interests:
            filters['required_interests'] = required_interests.split(',')
        
        # Use advanced matching service with safety check
        matches = await MatchingService.get_filtered_matches(current_user["id"], filters)
        
        # Add photo privacy and safety info
        enhanced_matches = []
        for match in matches:
            # Check safety
            is_flagged = await AntiScamService.is_user_flagged(match['id'])
            
            # Process photos with blur
            blurred_photos = []
            for photo_id in match.get('profile_images', []):
                photo_info = await PhotoPrivacyService.get_photo_url(
                    photo_id, current_user["id"], match['id']
                )
                blurred_photos.append(photo_info)
            
            match['profile_photos'] = blurred_photos
            match['is_flagged'] = is_flagged
            match['safety_verified'] = not is_flagged
            
            enhanced_matches.append(match)
        
        return {
            "users": enhanced_matches,
            "total_found": len(enhanced_matches),
            "filters_applied": filters
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch users: {str(e)}"
        )

@router.get("/nearby")
async def get_nearby_users(
    radius_km: float = Query(5.0, ge=0.1, le=50),
    limit: int = Query(20, le=100),
    current_user: dict = Depends(get_current_user)
):
    """Get users within specified radius"""
    try:
        user_lat = current_user.get("latitude")
        user_lon = current_user.get("longitude")
        
        if not user_lat or not user_lon:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Location not set. Please update your location first."
            )
        
        nearby_users = await LocationService.find_nearby_users(
            current_user["id"], user_lat, user_lon, radius_km, limit
        )
        
        return {
            "nearby_users": nearby_users,
            "radius_km": radius_km,
            "user_location": {
                "latitude": user_lat,
                "longitude": user_lon
            }
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to find nearby users: {str(e)}"
        )

@router.put("/location")
async def update_location(
    latitude: float,
    longitude: float,
    location_name: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Update user's location coordinates"""
    try:
        # Update database
        await db.execute(
            "UPDATE users SET latitude = ?, longitude = ?, location = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
            (latitude, longitude, location_name, current_user["id"])
        )
        await db.commit()
        
        return {
            "message": "Location updated successfully",
            "latitude": latitude,
            "longitude": longitude,
            "location_name": location_name
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update location: {str(e)}"
        )

@router.put("/interests")
async def update_interests(
    request: dict,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Update user's interests"""
    try:
        interests = request.get('interests', [])
        
        # Validate interests
        if not isinstance(interests, list):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Interests must be a list"
            )
        
        if len(interests) > 10:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Maximum 10 interests allowed"
            )
        
        # Update database
        await db.execute(
            "UPDATE users SET interests = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
            (json.dumps(interests), current_user["id"])
        )
        await db.commit()
        
        return {
            "message": "Interests updated successfully",
            "interests": interests,
            "available_interests": [
                # Lifestyle
                'Travel', 'Music', 'Movies', 'Sports', 'Reading', 'Cooking',
                'Photography', 'Gaming', 'Fitness', 'Art', 'Dancing', 'Yoga',
                
                # Hobbies
                'Hiking', 'Swimming', 'Cycling', 'Running', 'Gym', 'Meditation',
                'Painting', 'Writing', 'Singing', 'Guitar', 'Piano', 'Drawing',
                
                # Food & Drinks
                'Coffee', 'Wine', 'Beer', 'Cocktails', 'Vegetarian', 'Vegan',
                'Foodie', 'Baking', 'BBQ', 'Sushi', 'Pizza', 'Street Food',
                
                # Entertainment
                'Netflix', 'Comedy', 'Horror Movies', 'Action Movies', 'Romance',
                'Documentaries', 'Podcasts', 'Live Music', 'Concerts', 'Theater',
                
                # Outdoor Activities
                'Beach', 'Mountains', 'Camping', 'Fishing', 'Surfing', 'Skiing',
                'Rock Climbing', 'Kayaking', 'Sailing', 'Road Trips', 'Nature',
                
                # Social & Culture
                'Parties', 'Nightlife', 'Museums', 'Art Galleries', 'Fashion',
                'Shopping', 'Volunteering', 'Charity', 'Politics', 'Philosophy',
                
                # Technology & Learning
                'Technology', 'Coding', 'Startups', 'Investing', 'Crypto',
                'Learning Languages', 'History', 'Science', 'Astronomy', 'Books',
                
                # Pets & Animals
                'Dogs', 'Cats', 'Pets', 'Animal Lover', 'Wildlife', 'Horses',
                
                # Wellness & Spirituality
                'Mindfulness', 'Spirituality', 'Self-improvement', 'Therapy',
                'Mental Health', 'Wellness', 'Astrology', 'Tarot'
            ]
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update interests: {str(e)}"
        )

@router.put("/relationship-intent")
async def update_relationship_intent(
    intent: str,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Update user's relationship intent"""
    try:
        valid_intents = [
            'Long-term relationship',
            'Short-term relationship', 
            'Friendship',
            'Casual dating',
            'Not sure yet'
        ]
        
        if intent not in valid_intents:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid intent. Must be one of: {valid_intents}"
            )
        
        # Update database
        await db.execute(
            "UPDATE users SET relationship_intent = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
            (intent, current_user["id"])
        )
        await db.commit()
        
        return {
            "message": "Relationship intent updated successfully",
            "intent": intent,
            "available_intents": valid_intents
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update relationship intent: {str(e)}"
        )

@router.get("/interests")
async def get_available_interests():
    """Get list of available interests"""
    interests_list = [
        # Lifestyle
        'Travel', 'Music', 'Movies', 'Sports', 'Reading', 'Cooking',
        'Photography', 'Gaming', 'Fitness', 'Art', 'Dancing', 'Yoga',
        
        # Hobbies
        'Hiking', 'Swimming', 'Cycling', 'Running', 'Gym', 'Meditation',
        'Painting', 'Writing', 'Singing', 'Guitar', 'Piano', 'Drawing',
        
        # Food & Drinks
        'Coffee', 'Wine', 'Beer', 'Cocktails', 'Vegetarian', 'Vegan',
        'Foodie', 'Baking', 'BBQ', 'Sushi', 'Pizza', 'Street Food',
        
        # Entertainment
        'Netflix', 'Comedy', 'Horror Movies', 'Action Movies', 'Romance',
        'Documentaries', 'Podcasts', 'Live Music', 'Concerts', 'Theater',
        
        # Outdoor Activities
        'Beach', 'Mountains', 'Camping', 'Fishing', 'Surfing', 'Skiing',
        'Rock Climbing', 'Kayaking', 'Sailing', 'Road Trips', 'Nature',
        
        # Social & Culture
        'Parties', 'Nightlife', 'Museums', 'Art Galleries', 'Fashion',
        'Shopping', 'Volunteering', 'Charity', 'Politics', 'Philosophy',
        
        # Technology & Learning
        'Technology', 'Coding', 'Startups', 'Investing', 'Crypto',
        'Learning Languages', 'History', 'Science', 'Astronomy', 'Books',
        
        # Pets & Animals
        'Dogs', 'Cats', 'Pets', 'Animal Lover', 'Wildlife', 'Horses',
        
        # Wellness & Spirituality
        'Mindfulness', 'Spirituality', 'Self-improvement', 'Therapy',
        'Mental Health', 'Wellness', 'Astrology', 'Tarot'
    ]
    
    return {
        "interests": interests_list,
        "total_count": len(interests_list)
    }

@router.put("/photo-privacy")
async def update_photo_privacy(
    blur_enabled: bool,
    current_user: dict = Depends(get_current_user)
):
    """Update photo blur preference"""
    try:
        await PhotoPrivacyService.update_blur_preference(
            current_user["id"], blur_enabled
        )
        
        return {
            "message": "Photo privacy updated",
            "blur_enabled": blur_enabled
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update privacy: {str(e)}"
        )
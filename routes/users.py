from fastapi import APIRouter, Depends, HTTPException, status, Query
from typing import List, Optional, Dict
import json

from models.schemas import UserProfile, UserUpdate, ImageUpload
from routes.auth import get_current_user
from config.database import get_db
from services.location_service import LocationService
from services.matching_service import MatchingService
from services.photo_privacy_service import PhotoPrivacyService
from services.anti_scam_service import AntiScamService
from services.compatibility_service import CompatibilityService
from services.filter_service import FilterService

router = APIRouter()

@router.get("/profile", response_model=UserProfile)
async def get_profile(current_user: dict = Depends(get_current_user)):
    """Get current user profile"""
    from services.telegram_service import get_image_url
    from services.telegram_service import get_image_url
    
    # Convert file_ids to URLs
    profile_images = json.loads(current_user["profile_images"])
    image_urls = []
    for file_id in profile_images:
        try:
            url = await get_image_url(file_id)
            image_urls.append(url)
        except:
            image_urls.append("https://via.placeholder.com/400x400/FF6B6B/FFFFFF?text=HeartLink")
    
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
        profile_images=image_urls,  # Return URLs instead of file_ids
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
        profile_images=json.loads(user_dict["profile_images"]),  # Keep as file_ids for update
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
    limit: int = Query(20, le=50),
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Simple user discovery"""
    try:
        from services.telegram_service import get_image_url
        
        print(f"\n=== DISCOVER REQUEST ===")
        print(f"Current user ID: {current_user['id']}")
        print(f"Limit: {limit}")
        
        users = await db.fetchall("""
            SELECT id, name, age, bio, location, profile_images, interests, relationship_intent
            FROM users 
            WHERE id != ? AND is_blocked = 0
            LIMIT ?
        """, (current_user["id"], limit))
        
        print(f"Found {len(users)} users in database")
        
        user_list = []
        for user in users:
            user_dict = dict(user)
            print(f"Processing user: {user_dict['name']} (ID: {user_dict['id']})")
            
            # Convert file_ids to URLs
            profile_images = json.loads(user_dict.get("profile_images", "[]"))
            image_urls = []
            
            if profile_images:
                print(f"  Found {len(profile_images)} images")
                for file_id in profile_images[:3]:
                    try:
                        url = await get_image_url(file_id)
                        image_urls.append(url)
                        print(f"  Image URL: {url[:50]}...")
                    except Exception as e:
                        print(f"  Error getting image URL: {e}")
                        image_urls.append("https://via.placeholder.com/400x400/FF6B6B/FFFFFF?text=HeartLink")
            else:
                print(f"  No images, using placeholder")
                image_urls.append("https://via.placeholder.com/400x400/FF6B6B/FFFFFF?text=HeartLink")
            
            user_dict['profile_images'] = image_urls
            user_dict['interests'] = json.loads(user_dict.get('interests', '[]'))
            user_list.append(user_dict)
        
        print(f"Returning {len(user_list)} users")
        print(f"=== END DISCOVER ===")
        return {"users": user_list}
        
    except Exception as e:
        print(f"\n!!! DISCOVER ERROR: {e}")
        import traceback
        traceback.print_exc()
        return {"users": []}

@router.get("/discover-advanced")
async def discover_users_advanced(
    filters: Dict = {},
    limit: int = Query(20, le=50),
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Advanced user discovery with smart filters and compatibility"""
    try:
        from services.telegram_service import get_image_url
        
        # Apply smart filters
        users = await FilterService.apply_smart_filters(
            user_id=current_user["id"],
            filters=filters,
            limit=limit
        )
        
        enhanced_matches = []
        for user in users:
            # Convert file_ids to URLs
            profile_images = json.loads(user.get("profile_images", "[]"))
            image_urls = []
            
            if profile_images:
                for file_id in profile_images[:3]:
                    try:
                        url = await get_image_url(file_id)
                        image_urls.append(url)
                    except Exception as e:
                        print(f"Error getting image URL: {e}")
                        image_urls.append("https://via.placeholder.com/400x400/FF6B6B/FFFFFF?text=HeartLink")
            else:
                image_urls.append("https://via.placeholder.com/400x400/FF6B6B/FFFFFF?text=HeartLink")
            
            # Get compatibility score
            compatibility_score = await CompatibilityService.get_compatibility_score(
                current_user["id"], user['id']
            )
            
            user_data = {
                'id': user['id'],
                'name': user['name'],
                'age': user['age'],
                'bio': user['bio'],
                'location': user['location'],
                'job_title': user.get('job_title'),
                'education_level': user.get('education_level'),
                'height': user.get('height'),
                'interests': json.loads(user.get('interests', '[]')),
                'profile_images': image_urls,
                'compatibility_score': compatibility_score,
                'distance_km': user.get('distance_km', 0),
                'last_active': user.get('last_active')
            }
            
            enhanced_matches.append(user_data)
        
        return {
            "users": enhanced_matches,
            "total_found": len(enhanced_matches),
            "filters_applied": filters
        }
        
    except Exception as e:
        print(f"Advanced discover error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to fetch users: {str(e)}"
        )

@router.get("/nearby")
async def get_nearby_users(
    radius_km: float = Query(5.0, ge=0.1, le=50),
    limit: int = Query(20, le=100),
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Get users within specified radius"""
    try:
        from services.telegram_service import get_image_url
        
        # Only show users with recent GPS location (within 24 hours)
        users = await db.fetchall("""
            SELECT id, name, age, bio, location, profile_images, interests, relationship_intent, created_at, latitude, longitude
            FROM users 
            WHERE id != ? AND gps_updated_at > datetime('now', '-24 hours')
            LIMIT ?
        """, (current_user["id"], limit))
        
        print(f"Found {len(users)} nearby users")
        
        nearby_users = []
        for user in users:
            user_dict = dict(user)
            
            # Convert file_ids to URLs
            profile_images = json.loads(user_dict.get("profile_images", "[]"))
            image_urls = []
            
            if profile_images:
                for file_id in profile_images[:3]:
                    try:
                        url = await get_image_url(file_id)
                        image_urls.append(url)
                    except Exception as e:
                        print(f"Error getting image URL: {e}")
                        image_urls.append("https://via.placeholder.com/400x400/FF6B6B/FFFFFF?text=HeartLink")
            else:
                image_urls.append("https://via.placeholder.com/400x400/FF6B6B/FFFFFF?text=HeartLink")
            
            user_dict['profile_images'] = image_urls
            user_dict['interests'] = json.loads(user_dict.get('interests', '[]'))
            user_dict['distance_km'] = 2.5  # Mock distance
            nearby_users.append(user_dict)
        
        return {
            "nearby_users": nearby_users,
            "radius_km": radius_km,
            "user_location": {
                "latitude": current_user.get("latitude", 0),
                "longitude": current_user.get("longitude", 0)
            }
        }
        
    except Exception as e:
        print(f"Nearby error: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to find nearby users: {str(e)}"
        )

@router.post("/track-view/{user_id}")
async def track_profile_view(
    user_id: int,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Track when someone views a profile"""
    try:
        # Don't track self-views
        if user_id == current_user["id"]:
            return {"tracked": False}
        
        # Insert view record
        await db.execute(
            "INSERT INTO profile_views (viewer_id, viewed_id) VALUES (?, ?)",
            (current_user["id"], user_id)
        )
        await db.commit()
        
        return {"tracked": True}
        
    except Exception as e:
        print(f"Error tracking view: {e}")
        return {"tracked": False}

@router.get("/profile-views")
async def get_profile_views(
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Get who viewed your profile"""
    try:
        from services.telegram_service import get_image_url
        
        views = await db.fetchall("""
            SELECT u.id, u.name, u.age, u.profile_images, pv.created_at as viewed_at
            FROM profile_views pv
            JOIN users u ON pv.viewer_id = u.id
            WHERE pv.viewed_id = ?
            ORDER BY pv.created_at DESC
            LIMIT 50
        """, (current_user["id"],))
        
        viewers = []
        for view in views:
            view_dict = dict(view)
            profile_images = json.loads(view_dict.get("profile_images", "[]"))
            image_url = None
            
            if profile_images:
                try:
                    image_url = await get_image_url(profile_images[0])
                except:
                    image_url = "https://via.placeholder.com/400x400/FF6B6B/FFFFFF?text=HeartLink"
            
            viewers.append({
                "id": view_dict["id"],
                "name": view_dict["name"],
                "age": view_dict["age"],
                "profile_image": image_url,
                "viewed_at": view_dict["viewed_at"]
            })
        
        # Get total count
        total_count = await db.fetchone(
            "SELECT COUNT(*) as count FROM profile_views WHERE viewed_id = ?",
            (current_user["id"],)
        )
        
        return {
            "total_views": total_count["count"],
            "recent_viewers": viewers
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/location")
async def update_location(
    request: dict,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Update user's location coordinates (GPS only - no manual input)"""
    try:
        latitude = request.get('latitude')
        longitude = request.get('longitude')
        location_name = request.get('location_name')
        gps_accuracy = request.get('gps_accuracy', 0)
        
        if latitude is None or longitude is None:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="GPS coordinates required"
            )
        
        # Validate coordinates
        if not (-90 <= latitude <= 90):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid GPS latitude"
            )
        
        if not (-180 <= longitude <= 180):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid GPS longitude"
            )
        
        # Only accept high accuracy GPS (< 100 meters)
        if gps_accuracy > 100:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="GPS accuracy too low. Please enable high accuracy location."
            )
        
        # Update database with GPS timestamp
        await db.execute(
            "UPDATE users SET latitude = ?, longitude = ?, location = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?",
            (latitude, longitude, location_name, current_user["id"])
        )
        await db.commit()
        
        return {
            "message": "GPS location updated",
            "latitude": latitude,
            "longitude": longitude,
            "location_name": location_name,
            "accuracy": gps_accuracy
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update GPS location: {str(e)}"
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

@router.get("/filter-options")
async def get_filter_options():
    """Get all available filter options"""
    return FilterService.get_filter_options()

@router.get("/{user_id}/profile")
async def get_user_profile(
    user_id: int,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Get another user's profile"""
    try:
        from services.telegram_service import get_image_url
        
        user = await db.fetchone(
            "SELECT * FROM users WHERE id = ?",
            (user_id,)
        )
        
        if not user:
            raise HTTPException(status_code=404, detail="User not found")
        
        user_dict = dict(user)
        
        # Convert file_ids to URLs
        profile_images = json.loads(user_dict["profile_images"])
        image_urls = []
        for file_id in profile_images:
            try:
                url = await get_image_url(file_id)
                image_urls.append(url)
            except:
                image_urls.append("https://via.placeholder.com/400x400/FF6B6B/FFFFFF?text=HeartLink")
        
        return {
            "id": user_dict["id"],
            "name": user_dict["name"],
            "age": user_dict["age"],
            "bio": user_dict["bio"],
            "location": user_dict["location"],
            "interests": json.loads(user_dict.get("interests", "[]")),
            "relationship_intent": user_dict.get("relationship_intent"),
            "profile_images": image_urls,
            "is_verified": user_dict["is_verified"],
            "job_title": user_dict.get("job_title"),
            "education_level": user_dict.get("education_level"),
            "height": user_dict.get("height"),
        }
        
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.put("/rich-profile")
async def update_rich_profile(
    profile_data: dict,
    current_user: dict = Depends(get_current_user),
    db = Depends(get_db)
):
    """Update rich profile data"""
    try:
        update_fields = []
        update_values = []
        
        # Job & Education
        if 'job_title' in profile_data:
            update_fields.append("job_title = ?")
            update_values.append(profile_data['job_title'])
        
        if 'company' in profile_data:
            update_fields.append("company = ?")
            update_values.append(profile_data['company'])
        
        if 'education_level' in profile_data:
            update_fields.append("education_level = ?")
            update_values.append(profile_data['education_level'])
        
        if 'education_details' in profile_data:
            update_fields.append("education_details = ?")
            update_values.append(profile_data['education_details'])
        
        # Physical attributes
        if 'height' in profile_data:
            update_fields.append("height = ?")
            update_values.append(profile_data['height'])
        
        if 'body_type' in profile_data:
            update_fields.append("body_type = ?")
            update_values.append(profile_data['body_type'])
        
        # Lifestyle
        if 'smoking' in profile_data:
            update_fields.append("smoking = ?")
            update_values.append(profile_data['smoking'])
        
        if 'drinking' in profile_data:
            update_fields.append("drinking = ?")
            update_values.append(profile_data['drinking'])
        
        if 'diet_preference' in profile_data:
            update_fields.append("diet_preference = ?")
            update_values.append(profile_data['diet_preference'])
        
        # Cultural
        if 'religion' in profile_data:
            update_fields.append("religion = ?")
            update_values.append(profile_data['religion'])
        
        if 'caste' in profile_data:
            update_fields.append("caste = ?")
            update_values.append(profile_data['caste'])
        
        if 'mother_tongue' in profile_data:
            update_fields.append("mother_tongue = ?")
            update_values.append(profile_data['mother_tongue'])
        
        # Activity
        if 'gym_frequency' in profile_data:
            update_fields.append("gym_frequency = ?")
            update_values.append(profile_data['gym_frequency'])
        
        if 'travel_frequency' in profile_data:
            update_fields.append("travel_frequency = ?")
            update_values.append(profile_data['travel_frequency'])
        
        # Profile prompts
        if 'profile_prompts' in profile_data:
            update_fields.append("profile_prompts = ?")
            update_values.append(json.dumps(profile_data['profile_prompts']))
        
        if update_fields:
            update_fields.append("updated_at = CURRENT_TIMESTAMP")
            update_values.append(current_user["id"])
            
            query = f"UPDATE users SET {', '.join(update_fields)} WHERE id = ?"
            await db.execute(query, tuple(update_values))
            await db.commit()
        
        return {"message": "Rich profile updated successfully"}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to update rich profile: {str(e)}"
        )
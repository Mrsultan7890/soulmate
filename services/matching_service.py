import json
from typing import List, Dict, Optional
from config.database import db
from services.location_service import LocationService

class MatchingService:
    
    INTERESTS_LIST = [
        "Coding", "Gaming", "Anime", "Movies", "Music", "Travel", "Fitness", 
        "Reading", "Photography", "Cooking", "Dancing", "Sports", "Art", 
        "Technology", "Fashion", "Nature", "Pets", "Yoga", "Meditation",
        "Business", "Startups", "Investment", "Cryptocurrency", "AI/ML"
    ]
    
    RELATIONSHIP_INTENTS = ["serious", "casual", "friends"]
    
    @staticmethod
    def calculate_interest_compatibility(user_interests: List[str], 
                                       target_interests: List[str]) -> float:
        """Calculate compatibility score based on common interests (0-1)"""
        if not user_interests or not target_interests:
            return 0.0
        
        common_interests = set(user_interests) & set(target_interests)
        total_interests = set(user_interests) | set(target_interests)
        
        return len(common_interests) / len(total_interests) if total_interests else 0.0
    
    @staticmethod
    async def get_filtered_matches(user_id: int, filters: Dict) -> List[dict]:
        """Get potential matches with advanced filtering"""
        # Get user's profile first
        user_query = """
            SELECT latitude, longitude, interests, relationship_intent, age
            FROM users WHERE id = ?
        """
        user_data = await db.fetchone(user_query, (user_id,))
        
        if not user_data:
            return []
        
        user_lat, user_lon, user_interests_json, user_intent, user_age = user_data
        user_interests = json.loads(user_interests_json) if user_interests_json else []
        
        # Build dynamic query based on filters
        conditions = ["u.id != ?"]
        params = [user_id]
        
        # Age filter
        if filters.get('min_age'):
            conditions.append("u.age >= ?")
            params.append(filters['min_age'])
        if filters.get('max_age'):
            conditions.append("u.age <= ?")
            params.append(filters['max_age'])
        
        # Relationship intent filter
        if filters.get('relationship_intent'):
            conditions.append("u.relationship_intent = ?")
            params.append(filters['relationship_intent'])
        
        # Location filter (if user has location)
        if user_lat and user_lon and filters.get('max_distance_km'):
            conditions.append("u.latitude IS NOT NULL AND u.longitude IS NOT NULL")
        
        # Exclude already swiped users
        conditions.append("""
            u.id NOT IN (
                SELECT swiped_id FROM swipes WHERE swiper_id = ?
            )
        """)
        params.append(user_id)
        
        query = f"""
            SELECT u.id, u.name, u.age, u.bio, u.latitude, u.longitude, 
                   u.interests, u.relationship_intent, u.profile_images, u.location
            FROM users u
            WHERE {' AND '.join(conditions)}
            ORDER BY u.created_at DESC
            LIMIT 100
        """
        
        potential_matches = await db.fetchall(query, tuple(params))
        
        filtered_matches = []
        for match in potential_matches:
            match_data = {
                'id': match[0],
                'name': match[1],
                'age': match[2],
                'bio': match[3],
                'latitude': match[4],
                'longitude': match[5],
                'interests': json.loads(match[6]) if match[6] else [],
                'relationship_intent': match[7],
                'profile_images': json.loads(match[8]) if match[8] else [],
                'location': match[9],
                'compatibility_score': 0.0,
                'distance_km': None
            }
            
            # Calculate distance if both users have location
            if (user_lat and user_lon and match[4] and match[5]):
                distance = LocationService.calculate_distance(
                    user_lat, user_lon, match[4], match[5]
                )
                match_data['distance_km'] = round(distance, 2)
                
                # Skip if outside distance filter
                if filters.get('max_distance_km') and distance > filters['max_distance_km']:
                    continue
            
            # Calculate interest compatibility
            match_interests = json.loads(match[6]) if match[6] else []
            compatibility = MatchingService.calculate_interest_compatibility(
                user_interests, match_interests
            )
            match_data['compatibility_score'] = round(compatibility, 2)
            
            # Interest filter
            if filters.get('required_interests'):
                required = set(filters['required_interests'])
                match_interests_set = set(match_interests)
                if not required.intersection(match_interests_set):
                    continue
            
            filtered_matches.append(match_data)
        
        # Sort by compatibility score and distance
        filtered_matches.sort(
            key=lambda x: (x['compatibility_score'], -(x['distance_km'] or 999)), 
            reverse=True
        )
        
        return filtered_matches[:20]  # Return top 20 matches\n    \n    @staticmethod\n    async def update_user_interests(user_id: int, interests: List[str]):\n        \"\"\"Update user's interests\"\"\"\n        # Validate interests\n        valid_interests = [i for i in interests if i in MatchingService.INTERESTS_LIST]\n        \n        query = \"\"\"\n            UPDATE users \n            SET interests = ?, updated_at = CURRENT_TIMESTAMP\n            WHERE id = ?\n        \"\"\"\n        await db.execute(query, (json.dumps(valid_interests), user_id))\n        await db.commit()\n    \n    @staticmethod\n    async def update_relationship_intent(user_id: int, intent: str):\n        \"\"\"Update user's relationship intent\"\"\"\n        if intent not in MatchingService.RELATIONSHIP_INTENTS:\n            raise ValueError(f\"Invalid intent. Must be one of: {MatchingService.RELATIONSHIP_INTENTS}\")\n        \n        query = \"\"\"\n            UPDATE users \n            SET relationship_intent = ?, updated_at = CURRENT_TIMESTAMP\n            WHERE id = ?\n        \"\"\"\n        await db.execute(query, (intent, user_id))\n        await db.commit()
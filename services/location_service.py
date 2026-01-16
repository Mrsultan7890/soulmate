import math
from typing import List, Tuple, Optional
from config.database import db

class LocationService:
    @staticmethod
    def calculate_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
        """Calculate distance between two coordinates using Haversine formula (in km)"""
        R = 6371  # Earth's radius in kilometers
        
        lat1_rad = math.radians(lat1)
        lat2_rad = math.radians(lat2)
        delta_lat = math.radians(lat2 - lat1)
        delta_lon = math.radians(lon2 - lon1)
        
        a = (math.sin(delta_lat / 2) ** 2 + 
             math.cos(lat1_rad) * math.cos(lat2_rad) * 
             math.sin(delta_lon / 2) ** 2)
        c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
        
        return R * c
    
    @staticmethod
    async def find_nearby_users(user_id: int, latitude: float, longitude: float, 
                               radius_km: float = 5.0, limit: int = 50) -> List[dict]:
        """Find users within specified radius"""
        query = """
            SELECT id, name, age, bio, latitude, longitude, interests, relationship_intent,
                   profile_images, location
            FROM users 
            WHERE id != ? 
            AND latitude IS NOT NULL 
            AND longitude IS NOT NULL
            LIMIT ?
        """
        
        users = await db.fetchall(query, (user_id, limit * 3))  # Get more to filter by distance
        
        nearby_users = []
        for user in users:
            if user[4] and user[5]:  # latitude and longitude exist
                distance = LocationService.calculate_distance(
                    latitude, longitude, user[4], user[5]
                )
                
                if distance <= radius_km:
                    nearby_users.append({
                        'id': user[0],
                        'name': user[1],
                        'age': user[2],
                        'bio': user[3],
                        'latitude': user[4],
                        'longitude': user[5],
                        'interests': user[6],
                        'relationship_intent': user[7],
                        'profile_images': user[8],
                        'location': user[9],
                        'distance_km': round(distance, 2)
                    })
        
        # Sort by distance and limit results
        nearby_users.sort(key=lambda x: x['distance_km'])
        return nearby_users[:limit]
    
    @staticmethod
    async def update_user_location(user_id: int, latitude: float, longitude: float, 
                                  location_name: Optional[str] = None):
        """Update user's location coordinates"""
        query = """
            UPDATE users 
            SET latitude = ?, longitude = ?, location = ?
            WHERE id = ?
        """
        await db.execute(query, (latitude, longitude, location_name, user_id))
        await db.commit()
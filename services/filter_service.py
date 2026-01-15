from typing import Dict, List, Optional
from config.database import get_db
import json

class FilterService:
    
    @staticmethod
    async def apply_smart_filters(
        user_id: int,
        filters: Dict,
        limit: int = 20
    ) -> List[Dict]:
        """Apply smart filters to find compatible users"""
        
        db = await get_db()
        
        # Build dynamic query
        where_conditions = ["u.id != ?", "u.is_blocked = FALSE"]
        params = [user_id]
        
        # Age filter
        if filters.get('min_age'):
            where_conditions.append("u.age >= ?")
            params.append(filters['min_age'])
        
        if filters.get('max_age'):
            where_conditions.append("u.age <= ?")
            params.append(filters['max_age'])
        
        # Distance filter (if user has location)
        if filters.get('max_distance_km'):
            # Add distance calculation in query
            where_conditions.append("""
                (6371 * acos(cos(radians(?)) * cos(radians(u.latitude)) * 
                cos(radians(u.longitude) - radians(?)) + sin(radians(?)) * 
                sin(radians(u.latitude)))) <= ?
            """)
            # Get current user's location
            current_user = await db.fetchone("SELECT latitude, longitude FROM users WHERE id = ?", (user_id,))
            if current_user and current_user[0] and current_user[1]:
                params.extend([current_user[0], current_user[1], current_user[0], filters['max_distance_km']])
            else:
                # Skip distance filter if no location
                where_conditions.pop()
        
        # Education level filter
        if filters.get('education_levels'):
            education_placeholders = ','.join(['?' for _ in filters['education_levels']])
            where_conditions.append(f"u.education_level IN ({education_placeholders})")
            params.extend(filters['education_levels'])
        
        # Height filter
        if filters.get('min_height'):
            where_conditions.append("u.height >= ?")
            params.append(filters['min_height'])
        
        if filters.get('max_height'):
            where_conditions.append("u.height <= ?")
            params.append(filters['max_height'])
        
        # Body type filter
        if filters.get('body_types'):
            body_placeholders = ','.join(['?' for _ in filters['body_types']])
            where_conditions.append(f"u.body_type IN ({body_placeholders})")
            params.extend(filters['body_types'])
        
        # Smoking preference
        if filters.get('smoking_preferences'):
            smoking_placeholders = ','.join(['?' for _ in filters['smoking_preferences']])
            where_conditions.append(f"u.smoking IN ({smoking_placeholders})")
            params.extend(filters['smoking_preferences'])
        
        # Drinking preference
        if filters.get('drinking_preferences'):
            drinking_placeholders = ','.join(['?' for _ in filters['drinking_preferences']])
            where_conditions.append(f"u.drinking IN ({drinking_placeholders})")
            params.extend(filters['drinking_preferences'])
        
        # Religion filter
        if filters.get('religions'):
            religion_placeholders = ','.join(['?' for _ in filters['religions']])
            where_conditions.append(f"u.religion IN ({religion_placeholders})")
            params.extend(filters['religions'])
        
        # Diet preference
        if filters.get('diet_preferences'):
            diet_placeholders = ','.join(['?' for _ in filters['diet_preferences']])
            where_conditions.append(f"u.diet_preference IN ({diet_placeholders})")
            params.extend(filters['diet_preferences'])
        
        # Relationship intent
        if filters.get('relationship_intents'):
            intent_placeholders = ','.join(['?' for _ in filters['relationship_intents']])
            where_conditions.append(f"u.relationship_intent IN ({intent_placeholders})")
            params.extend(filters['relationship_intents'])
        
        # Only show users with recent GPS location (within 24 hours)
        where_conditions.append("u.gps_updated_at > datetime('now', '-24 hours')")
        
        # Build final query
        where_clause = " AND ".join(where_conditions)
        
        query = f"""
            SELECT u.*, 
                   CASE 
                       WHEN u.latitude IS NOT NULL AND u.longitude IS NOT NULL 
                       THEN (6371 * acos(cos(radians(?)) * cos(radians(u.latitude)) * 
                            cos(radians(u.longitude) - radians(?)) + sin(radians(?)) * 
                            sin(radians(u.latitude))))
                       ELSE 999999 
                   END as distance_km
            FROM users u
            WHERE {where_clause}
            ORDER BY 
                CASE WHEN ? = 'compatibility' THEN 
                    (SELECT overall_score FROM compatibility_scores cs 
                     WHERE (cs.user1_id = ? AND cs.user2_id = u.id) OR 
                           (cs.user2_id = ? AND cs.user1_id = u.id)) 
                END DESC,
                CASE WHEN ? = 'distance' THEN distance_km END ASC,
                CASE WHEN ? = 'activity' THEN u.last_active END DESC,
                u.created_at DESC
            LIMIT ?
        """
        
        # Get current user location for distance calculation
        current_user = await db.fetchone("SELECT latitude, longitude FROM users WHERE id = ?", (user_id,))
        user_lat = current_user[0] if current_user and current_user[0] else 0
        user_lon = current_user[1] if current_user and current_user[1] else 0
        
        # Sort preference
        sort_by = filters.get('sort_by', 'recent')
        
        # Add parameters for distance calculation and sorting
        final_params = [user_lat, user_lon, user_lat] + params + [sort_by, user_id, user_id, sort_by, sort_by, limit]
        
        users = await db.fetchall(query, tuple(final_params))
        
        return [dict(user) for user in users]
    
    @staticmethod
    def get_filter_options() -> Dict:
        """Get all available filter options"""
        return {
            "education_levels": [
                "High School",
                "Bachelor's Degree", 
                "Master's Degree",
                "PhD",
                "Diploma",
                "Professional Course",
                "Other"
            ],
            "body_types": [
                "Slim",
                "Average", 
                "Athletic",
                "Curvy",
                "Plus Size"
            ],
            "smoking_preferences": [
                "Never",
                "Occasionally", 
                "Regularly",
                "Trying to quit"
            ],
            "drinking_preferences": [
                "Never",
                "Socially",
                "Occasionally", 
                "Regularly"
            ],
            "religions": [
                "Hindu",
                "Muslim", 
                "Christian",
                "Sikh",
                "Buddhist",
                "Jain",
                "Other",
                "Prefer not to say"
            ],
            "diet_preferences": [
                "Vegetarian",
                "Non-Vegetarian",
                "Vegan", 
                "Jain",
                "Eggetarian"
            ],
            "relationship_intents": [
                "Long-term relationship",
                "Short-term relationship",
                "Friendship", 
                "Casual dating",
                "Not sure yet"
            ],
            "sort_options": [
                {"value": "recent", "label": "Recently Active"},
                {"value": "distance", "label": "Distance"},
                {"value": "compatibility", "label": "Compatibility"},
                {"value": "activity", "label": "Most Active"}
            ]
        }
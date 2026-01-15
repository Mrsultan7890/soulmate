import json
import math
from typing import Dict, List, Tuple
from config.database import get_db

class CompatibilityService:
    
    @staticmethod
    async def calculate_compatibility_score(user1_id: int, user2_id: int) -> float:
        """Calculate overall compatibility score between two users"""
        db = await get_db()
        
        # Get user data
        user1 = await db.fetchone("SELECT * FROM users WHERE id = ?", (user1_id,))
        user2 = await db.fetchone("SELECT * FROM users WHERE id = ?", (user2_id,))
        
        if not user1 or not user2:
            return 0.0
        
        user1_dict = dict(user1)
        user2_dict = dict(user2)
        
        # Calculate individual scores
        interest_score = CompatibilityService._calculate_interest_compatibility(user1_dict, user2_dict)
        lifestyle_score = CompatibilityService._calculate_lifestyle_compatibility(user1_dict, user2_dict)
        activity_score = CompatibilityService._calculate_activity_compatibility(user1_dict, user2_dict)
        
        # Weighted overall score
        overall_score = (
            interest_score * 0.4 +
            lifestyle_score * 0.4 +
            activity_score * 0.2
        )
        
        # Store compatibility score
        await db.execute("""
            INSERT OR REPLACE INTO compatibility_scores 
            (user1_id, user2_id, interest_score, lifestyle_score, activity_score, overall_score)
            VALUES (?, ?, ?, ?, ?, ?)
        """, (user1_id, user2_id, interest_score, lifestyle_score, activity_score, overall_score))
        
        await db.commit()
        
        return round(overall_score, 2)
    
    @staticmethod
    def _calculate_interest_compatibility(user1: dict, user2: dict) -> float:
        """Calculate compatibility based on shared interests"""
        try:
            interests1 = set(json.loads(user1.get('interests', '[]')))
            interests2 = set(json.loads(user2.get('interests', '[]')))
            
            if not interests1 or not interests2:
                return 0.5  # Neutral score if no interests
            
            # Jaccard similarity
            intersection = len(interests1.intersection(interests2))
            union = len(interests1.union(interests2))
            
            return intersection / union if union > 0 else 0.0
            
        except:
            return 0.5
    
    @staticmethod
    def _calculate_lifestyle_compatibility(user1: dict, user2: dict) -> float:
        """Calculate compatibility based on lifestyle choices"""
        score = 0.0
        factors = 0
        
        # Smoking compatibility
        if user1.get('smoking') and user2.get('smoking'):
            if user1['smoking'] == user2['smoking']:
                score += 1.0
            elif 'Never' in [user1['smoking'], user2['smoking']]:
                score += 0.3  # Lower compatibility if one doesn't smoke
            else:
                score += 0.7  # Moderate compatibility
            factors += 1
        
        # Drinking compatibility
        if user1.get('drinking') and user2.get('drinking'):
            if user1['drinking'] == user2['drinking']:
                score += 1.0
            elif 'Never' in [user1['drinking'], user2['drinking']]:
                score += 0.3
            else:
                score += 0.7
            factors += 1
        
        # Diet compatibility
        if user1.get('diet_preference') and user2.get('diet_preference'):
            if user1['diet_preference'] == user2['diet_preference']:
                score += 1.0
            elif 'Vegetarian' in [user1['diet_preference'], user2['diet_preference']] and \
                 'Non-Vegetarian' in [user1['diet_preference'], user2['diet_preference']]:
                score += 0.4  # Lower compatibility for veg/non-veg
            else:
                score += 0.8
            factors += 1
        
        # Religion compatibility (if both specified)
        if user1.get('religion') and user2.get('religion'):
            if user1['religion'] == user2['religion']:
                score += 1.0
            else:
                score += 0.6  # Moderate compatibility for different religions
            factors += 1
        
        return score / factors if factors > 0 else 0.5
    
    @staticmethod
    def _calculate_activity_compatibility(user1: dict, user2: dict) -> float:
        """Calculate compatibility based on activity levels"""
        activity_levels = {'Low': 1, 'Medium': 2, 'High': 3}
        
        level1 = activity_levels.get(user1.get('activity_level', 'Medium'), 2)
        level2 = activity_levels.get(user2.get('activity_level', 'Medium'), 2)
        
        # Calculate similarity (closer levels = higher compatibility)
        difference = abs(level1 - level2)
        
        if difference == 0:
            return 1.0
        elif difference == 1:
            return 0.7
        else:
            return 0.4
    
    @staticmethod
    async def get_compatibility_score(user1_id: int, user2_id: int) -> float:
        """Get existing compatibility score or calculate new one"""
        db = await get_db()
        
        # Try to get existing score
        score_record = await db.fetchone("""
            SELECT overall_score FROM compatibility_scores 
            WHERE (user1_id = ? AND user2_id = ?) OR (user1_id = ? AND user2_id = ?)
        """, (user1_id, user2_id, user2_id, user1_id))
        
        if score_record:
            return score_record[0]
        
        # Calculate new score
        return await CompatibilityService.calculate_compatibility_score(user1_id, user2_id)
    
    @staticmethod
    async def get_top_compatible_users(user_id: int, limit: int = 20) -> List[Dict]:
        """Get most compatible users for given user"""
        db = await get_db()
        
        # Get users with compatibility scores
        compatible_users = await db.fetchall("""
            SELECT u.*, cs.overall_score
            FROM users u
            JOIN compatibility_scores cs ON 
                (cs.user1_id = ? AND cs.user2_id = u.id) OR 
                (cs.user2_id = ? AND cs.user1_id = u.id)
            WHERE u.id != ? AND u.is_blocked = FALSE
            ORDER BY cs.overall_score DESC
            LIMIT ?
        """, (user_id, user_id, user_id, limit))
        
        return [dict(user) for user in compatible_users]
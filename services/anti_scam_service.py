import re
from typing import List, Dict, Optional
from config.database import db
import json
from datetime import datetime

class AntiScamService:
    
    # Suspicious patterns
    PHONE_PATTERNS = [
        r'\b\d{10}\b',  # 10 digit numbers
        r'\b\d{3}[-.\s]?\d{3}[-.\s]?\d{4}\b',  # Phone formats
        r'\+\d{1,3}[-.\s]?\d{8,12}\b',  # International numbers
    ]
    
    SUSPICIOUS_KEYWORDS = [
        'whatsapp', 'telegram', 'instagram', 'snapchat', 'kik',
        'phone number', 'call me', 'text me', 'my number',
        'money', 'cash', 'payment', 'send money', 'bitcoin',
        'investment', 'business opportunity', 'make money',
        'sugar daddy', 'sugar baby', 'financial help',
        'lonely', 'widow', 'military', 'overseas',
        'verification', 'verify account', 'click link',
        'cam', 'webcam', 'video call', 'private show'
    ]
    
    INSTANT_REQUEST_KEYWORDS = [
        'give me your number', 'send your number', 'what\'s your number',
        'can i have your number', 'share your contact', 'let\'s move to',
        'add me on', 'follow me on', 'find me on'
    ]
    
    @staticmethod
    def analyze_message(content: str, sender_id: int, match_id: int) -> Dict:
        """Analyze message for suspicious content"""
        content_lower = content.lower()
        flags = []
        risk_score = 0
        
        # Check for phone numbers
        for pattern in AntiScamService.PHONE_PATTERNS:
            if re.search(pattern, content):
                flags.append('phone_number_detected')
                risk_score += 30
        
        # Check suspicious keywords
        for keyword in AntiScamService.SUSPICIOUS_KEYWORDS:
            if keyword in content_lower:
                flags.append(f'suspicious_keyword: {keyword}')
                risk_score += 15
        
        # Check instant requests
        for keyword in AntiScamService.INSTANT_REQUEST_KEYWORDS:
            if keyword in content_lower:
                flags.append('instant_contact_request')
                risk_score += 25
        
        # Check message timing (too fast responses)
        if AntiScamService._is_too_fast_response(sender_id, match_id):
            flags.append('rapid_messaging')
            risk_score += 10
        
        return {
            'is_suspicious': risk_score >= 25,
            'risk_score': risk_score,
            'flags': flags,
            'action_required': risk_score >= 50
        }
    
    @staticmethod
    async def _is_too_fast_response(sender_id: int, match_id: int) -> bool:
        """Check if user is sending messages too quickly"""
        recent_messages = await db.fetchall("""
            SELECT created_at FROM messages 
            WHERE sender_id = ? AND match_id = ? 
            ORDER BY created_at DESC LIMIT 3
        """, (sender_id, match_id))
        
        if len(recent_messages) >= 3:
            # Check if 3 messages sent within 30 seconds
            time_diff = recent_messages[0][0] - recent_messages[2][0]
            return time_diff.total_seconds() < 30
        
        return False
    
    @staticmethod
    async def flag_user(user_id: int, reason: str, reported_by: int, evidence: Dict):
        """Flag a user for suspicious behavior"""
        await db.execute("""
            INSERT INTO user_flags (user_id, reason, reported_by, evidence, created_at)
            VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP)
        """, (user_id, reason, reported_by, json.dumps(evidence)))
        
        # Update user's flag count
        await db.execute("""
            UPDATE users SET flag_count = COALESCE(flag_count, 0) + 1 
            WHERE id = ?
        """, (user_id,))
        
        await db.commit()
    
    @staticmethod
    async def get_user_flags(user_id: int) -> List[Dict]:
        """Get all flags for a user"""
        flags = await db.fetchall("""
            SELECT reason, evidence, created_at, reported_by
            FROM user_flags WHERE user_id = ?
            ORDER BY created_at DESC
        """, (user_id,))
        
        return [
            {
                'reason': flag[0],
                'evidence': json.loads(flag[1]),
                'created_at': flag[2],
                'reported_by': flag[3]
            }
            for flag in flags
        ]
    
    @staticmethod
    async def is_user_flagged(user_id: int) -> bool:
        """Check if user has been flagged multiple times"""
        result = await db.fetchone("""
            SELECT COALESCE(flag_count, 0) FROM users WHERE id = ?
        """, (user_id,))
        
        return result and result[0] >= 3
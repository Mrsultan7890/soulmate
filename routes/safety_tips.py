from fastapi import APIRouter, Depends, HTTPException, status
from config.database import get_db
from routes.auth import get_current_user

router = APIRouter()

@router.get("/safety-tips")
async def get_safety_tips(
    category: str = "all",  # 'meeting', 'online', 'general', 'all'
    db = Depends(get_db)
):
    """Get safety tips by category"""
    try:
        if category == "all":
            tips = await db.fetchall("""
                SELECT * FROM safety_tips WHERE is_active = TRUE ORDER BY category, id
            """)
        else:
            tips = await db.fetchall("""
                SELECT * FROM safety_tips WHERE category = ? AND is_active = TRUE ORDER BY id
            """, (category,))
        
        return {
            "tips": [dict(tip) for tip in tips],
            "category": category
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get safety tips: {str(e)}"
        )

@router.post("/initialize-safety-tips")
async def initialize_safety_tips(db = Depends(get_db)):
    """Initialize default safety tips (admin only)"""
    try:
        # Meeting safety tips
        meeting_tips = [
            {
                "title": "Meet in Public Places",
                "content": "Always choose crowded, public locations for first meetings like cafes, restaurants, or shopping malls.",
                "category": "meeting"
            },
            {
                "title": "Tell Someone Your Plans", 
                "content": "Inform a trusted friend or family member about your date plans, including location and expected return time.",
                "category": "meeting"
            },
            {
                "title": "Arrange Your Own Transportation",
                "content": "Drive yourself or use your own ride service. Don't rely on your date for transportation.",
                "category": "meeting"
            },
            {
                "title": "Stay Sober",
                "content": "Limit alcohol consumption and never leave your drink unattended. Stay alert and in control.",
                "category": "meeting"
            },
            {
                "title": "Trust Your Instincts",
                "content": "If something feels wrong or uncomfortable, don't hesitate to leave. Your safety comes first.",
                "category": "meeting"
            }
        ]
        
        # Online safety tips
        online_tips = [
            {
                "title": "Protect Personal Information",
                "content": "Don't share your home address, workplace details, or financial information until you build trust.",
                "category": "online"
            },
            {
                "title": "Video Chat Before Meeting",
                "content": "Have a video call to verify the person matches their profile photos before meeting in person.",
                "category": "online"
            },
            {
                "title": "Be Cautious with Photos",
                "content": "Avoid sending intimate or compromising photos that could be misused later.",
                "category": "online"
            },
            {
                "title": "Report Suspicious Behavior",
                "content": "Report users who ask for money, seem fake, or make you uncomfortable. Help keep the community safe.",
                "category": "online"
            },
            {
                "title": "Use App's Communication Features",
                "content": "Keep conversations within the app initially. Don't rush to share personal contact details.",
                "category": "online"
            }
        ]
        
        # General safety tips
        general_tips = [
            {
                "title": "Verify Profile Authenticity",
                "content": "Look for verified profiles and be cautious of profiles with limited photos or information.",
                "category": "general"
            },
            {
                "title": "Take Your Time",
                "content": "Don't rush into meetings or relationships. Take time to get to know the person properly.",
                "category": "general"
            },
            {
                "title": "Emergency Contacts",
                "content": "Keep emergency contacts easily accessible and consider sharing your live location with trusted contacts.",
                "category": "general"
            },
            {
                "title": "Background Research",
                "content": "It's okay to do some basic online research about your date, but respect privacy boundaries.",
                "category": "general"
            },
            {
                "title": "Set Boundaries",
                "content": "Clearly communicate your boundaries and respect others' boundaries. Consent is essential.",
                "category": "general"
            }
        ]
        
        all_tips = meeting_tips + online_tips + general_tips
        
        # Insert tips
        for tip in all_tips:
            await db.execute("""
                INSERT OR IGNORE INTO safety_tips (title, content, category)
                VALUES (?, ?, ?)
            """, (tip["title"], tip["content"], tip["category"]))
        
        await db.commit()
        
        return {"message": f"Initialized {len(all_tips)} safety tips"}
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to initialize safety tips: {str(e)}"
        )

@router.get("/safety-resources")
async def get_safety_resources():
    """Get safety resources and emergency contacts"""
    return {
        "emergency_contacts": {
            "police": "100",
            "women_helpline": "1091", 
            "cyber_crime": "1930",
            "national_emergency": "112"
        },
        "safety_apps": [
            {
                "name": "bSafe",
                "description": "Personal safety app with SOS features"
            },
            {
                "name": "Himmat Plus",
                "description": "Delhi Police safety app for women"
            },
            {
                "name": "Smart24x7",
                "description": "Emergency response and safety app"
            }
        ],
        "dating_safety_checklist": [
            "✓ Profile is verified",
            "✓ Had video chat before meeting", 
            "✓ Meeting in public place",
            "✓ Told someone about date plans",
            "✓ Have own transportation arranged",
            "✓ Emergency contacts accessible"
        ]
    }
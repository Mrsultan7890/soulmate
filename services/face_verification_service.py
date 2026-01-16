import cv2
import numpy as np
from PIL import Image
import base64
import io
import hashlib
import os

class FaceVerificationService:
    def __init__(self):
        self.face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
        self.deepface_available = False
        
    def detect_gender_simple(self, image_array):
        """Gender detection using DeepFace (only gender model - 23MB)"""
        try:
            # Lazy load DeepFace
            if not self.deepface_available:
                try:
                    from deepface import DeepFace
                    self.deepface_available = True
                    print("✓ DeepFace loaded successfully")
                except Exception as e:
                    print(f"✗ DeepFace not available: {e}")
                    pass
            
            if self.deepface_available:
                from deepface import DeepFace
                
                print("[DEBUG] Using DeepFace for gender detection")
                
                # Only analyze gender (downloads only gender model ~23MB)
                result = DeepFace.analyze(
                    img_path=image_array,
                    actions=['gender'],
                    enforce_detection=False,
                    detector_backend='opencv',
                    silent=True
                )
                
                if isinstance(result, list):
                    result = result[0]
                
                dominant_gender = result['dominant_gender']
                confidence = result['gender'][dominant_gender]
                
                print(f"[DEBUG] DeepFace result: {dominant_gender} ({confidence:.1f}%)")
                
                gender = 'male' if dominant_gender.lower() == 'man' else 'female'
                
                return gender, f"Detected with {confidence:.1f}% confidence"
            else:
                print("[DEBUG] Using fallback detection")
                return self._fallback_detection(image_array)
                
        except Exception as e:
            print(f"DeepFace error: {e}")
            import traceback
            print(traceback.format_exc())
            return self._fallback_detection(image_array)
    
    def _fallback_detection(self, image_array):
        """Fallback using OpenCV"""
        try:
            gray = cv2.cvtColor(image_array, cv2.COLOR_BGR2GRAY)
            faces = self.face_cascade.detectMultiScale(gray, 1.1, 4, minSize=(30, 30))
            
            if len(faces) == 0:
                return None, "No face detected"
            
            face = max(faces, key=lambda x: x[2] * x[3])
            x, y, w, h = face
            face_ratio = w / h
            
            gender = 'male' if face_ratio > 0.88 else 'female'
            return gender, "Detected with basic analysis"
        except:
            return None, "Face detection failed"
    
    def verify_face_match(self, image1_b64, image2_b64):
        """Compare two faces"""
        try:
            img1 = self.base64_to_image(image1_b64)
            img2 = self.base64_to_image(image2_b64)
            
            gray1 = cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)
            gray2 = cv2.cvtColor(img2, cv2.COLOR_BGR2GRAY)
            
            faces1 = self.face_cascade.detectMultiScale(gray1, 1.3, 5)
            faces2 = self.face_cascade.detectMultiScale(gray2, 1.3, 5)
            
            if len(faces1) == 0 or len(faces2) == 0:
                return False, "Face not detected"
            
            face1 = max(faces1, key=lambda x: x[2] * x[3])
            face2 = max(faces2, key=lambda x: x[2] * x[3])
            
            x1, y1, w1, h1 = face1
            x2, y2, w2, h2 = face2
            
            face_roi1 = cv2.resize(gray1[y1:y1+h1, x1:x1+w1], (100, 100))
            face_roi2 = cv2.resize(gray2[y2:y2+h2, x2:x2+w2], (100, 100))
            
            result = cv2.matchTemplate(face_roi1, face_roi2, cv2.TM_CCOEFF_NORMED)
            similarity = np.max(result)
            
            return similarity > 0.6, f"Similarity: {similarity:.2f}"
            
        except Exception as e:
            return False, f"Error: {str(e)}"
    
    def base64_to_image(self, base64_string):
        """Convert base64 to OpenCV image"""
        if base64_string.startswith('data:'):
            base64_string = base64_string.split(',')[1]
        
        image_data = base64.b64decode(base64_string)
        image = Image.open(io.BytesIO(image_data))
        return cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
    
    def generate_face_hash(self, image_b64):
        """Generate face hash"""
        try:
            img = self.base64_to_image(image_b64)
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            
            faces = self.face_cascade.detectMultiScale(gray, 1.3, 5)
            if len(faces) == 0:
                return None
            
            face = max(faces, key=lambda x: x[2] * x[3])
            x, y, w, h = face
            
            face_roi = cv2.resize(gray[y:y+h, x:x+w], (64, 64))
            return hashlib.md5(face_roi.tobytes()).hexdigest()
            
        except:
            return None
    
    def create_avatar_data(self, gender, image_b64):
        """Create avatar data"""
        try:
            img = self.base64_to_image(image_b64)
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            
            faces = self.face_cascade.detectMultiScale(gray, 1.3, 5)
            if len(faces) == 0:
                return self.default_avatar(gender)
            
            face = max(faces, key=lambda x: x[2] * x[3])
            x, y, w, h = face
            face_ratio = w / h
            
            return {
                "gender": gender,
                "face_shape": "round" if face_ratio > 0.9 else "oval",
                "style": "casual" if gender == "male" else "elegant",
                "color_scheme": self.get_color_scheme(gender)
            }
        except:
            return self.default_avatar(gender)
    
    def default_avatar(self, gender):
        return {
            "gender": gender or "unknown",
            "face_shape": "oval",
            "style": "casual" if gender == "male" else "elegant",
            "color_scheme": self.get_color_scheme(gender)
        }
    
    def get_color_scheme(self, gender):
        if gender == "male":
            return ["#4A90E2", "#2E5BBA", "#1E3A8A"]
        else:
            return ["#E24A90", "#BA2E5B", "#8A1E3A"]

# Global instance
try:
    face_service = FaceVerificationService()
    print("✓ Face service initialized")
except Exception as e:
    print(f"Warning: {e}")
    face_service = None

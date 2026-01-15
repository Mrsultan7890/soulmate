import cv2
import numpy as np
from PIL import Image
import base64
import io
import hashlib

class FaceVerificationService:
    def __init__(self):
        # Load lightweight Haar cascade (only ~1MB)
        self.face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
        self.eye_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_eye.xml')
        
    def detect_gender_simple(self, image_array):
        """Simple gender detection based on facial features (no ML model)"""
        gray = cv2.cvtColor(image_array, cv2.COLOR_BGR2GRAY)
        faces = self.face_cascade.detectMultiScale(gray, 1.3, 5)
        
        if len(faces) == 0:
            return None, "No face detected"
        
        # Get the largest face
        face = max(faces, key=lambda x: x[2] * x[3])
        x, y, w, h = face
        
        # Extract face region
        face_roi = gray[y:y+h, x:x+w]
        
        # Simple heuristics for gender detection
        # Based on facial structure analysis
        face_ratio = w / h
        
        # Detect eyes in face region
        eyes = self.eye_cascade.detectMultiScale(face_roi)
        eye_distance = 0
        
        if len(eyes) >= 2:
            # Calculate distance between eyes
            eye1, eye2 = eyes[0], eyes[1]
            eye_distance = abs(eye1[0] - eye2[0])
        
        # Simple gender classification based on ratios
        # These are basic heuristics, not 100% accurate
        if face_ratio > 0.85 and eye_distance > w * 0.3:
            return "male", "Detected based on facial structure"
        else:
            return "female", "Detected based on facial structure"
    
    def verify_face_match(self, image1_b64, image2_b64):
        """Compare two faces using template matching"""
        try:
            # Decode base64 images
            img1 = self.base64_to_image(image1_b64)
            img2 = self.base64_to_image(image2_b64)
            
            # Convert to grayscale
            gray1 = cv2.cvtColor(img1, cv2.COLOR_BGR2GRAY)
            gray2 = cv2.cvtColor(img2, cv2.COLOR_BGR2GRAY)
            
            # Detect faces
            faces1 = self.face_cascade.detectMultiScale(gray1, 1.3, 5)
            faces2 = self.face_cascade.detectMultiScale(gray2, 1.3, 5)
            
            if len(faces1) == 0 or len(faces2) == 0:
                return False, "Face not detected in one or both images"
            
            # Get largest faces
            face1 = max(faces1, key=lambda x: x[2] * x[3])
            face2 = max(faces2, key=lambda x: x[2] * x[3])
            
            # Extract face regions
            x1, y1, w1, h1 = face1
            x2, y2, w2, h2 = face2
            
            face_roi1 = gray1[y1:y1+h1, x1:x1+w1]
            face_roi2 = gray2[y2:y2+h2, x2:x2+w2]
            
            # Resize to same size for comparison
            face_roi1 = cv2.resize(face_roi1, (100, 100))
            face_roi2 = cv2.resize(face_roi2, (100, 100))
            
            # Template matching
            result = cv2.matchTemplate(face_roi1, face_roi2, cv2.TM_CCOEFF_NORMED)
            similarity = np.max(result)
            
            # Threshold for match (adjust as needed)
            is_match = similarity > 0.6
            
            return is_match, f"Similarity: {similarity:.2f}"
            
        except Exception as e:
            return False, f"Error: {str(e)}"
    
    def base64_to_image(self, base64_string):
        """Convert base64 string to OpenCV image"""
        if base64_string.startswith('data:'):
            base64_string = base64_string.split(',')[1]
        
        image_data = base64.b64decode(base64_string)
        image = Image.open(io.BytesIO(image_data))
        return cv2.cvtColor(np.array(image), cv2.COLOR_RGB2BGR)
    
    def generate_face_hash(self, image_b64):
        """Generate unique hash for face (for duplicate detection)"""
        try:
            img = self.base64_to_image(image_b64)
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            
            faces = self.face_cascade.detectMultiScale(gray, 1.3, 5)
            if len(faces) == 0:
                return None
            
            # Get largest face
            face = max(faces, key=lambda x: x[2] * x[3])
            x, y, w, h = face
            
            # Extract and normalize face
            face_roi = gray[y:y+h, x:x+w]
            face_roi = cv2.resize(face_roi, (64, 64))
            
            # Create hash from face features
            face_hash = hashlib.md5(face_roi.tobytes()).hexdigest()
            return face_hash
            
        except Exception as e:
            return None
    
    def create_avatar_data(self, gender, image_b64):
        """Create avatar data based on gender and facial features"""
        try:
            img = self.base64_to_image(image_b64)
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            
            faces = self.face_cascade.detectMultiScale(gray, 1.3, 5)
            if len(faces) == 0:
                return self.default_avatar(gender)
            
            face = max(faces, key=lambda x: x[2] * x[3])
            x, y, w, h = face
            
            # Analyze facial features
            face_roi = gray[y:y+h, x:x+w]
            
            # Simple feature extraction
            face_ratio = w / h
            
            # Generate avatar characteristics
            avatar_data = {
                "gender": gender,
                "face_shape": "round" if face_ratio > 0.9 else "oval",
                "style": "casual" if gender == "male" else "elegant",
                "color_scheme": self.get_color_scheme(gender)
            }
            
            return avatar_data
            
        except Exception as e:
            return self.default_avatar(gender)
    
    def default_avatar(self, gender):
        """Default avatar data"""
        return {
            "gender": gender or "unknown",
            "face_shape": "oval",
            "style": "casual" if gender == "male" else "elegant",
            "color_scheme": self.get_color_scheme(gender)
        }
    
    def get_color_scheme(self, gender):
        """Get color scheme based on gender"""
        if gender == "male":
            return ["#4A90E2", "#2E5BBA", "#1E3A8A"]  # Blue tones
        else:
            return ["#E24A90", "#BA2E5B", "#8A1E3A"]  # Pink tones

# Global instance
face_service = FaceVerificationService()
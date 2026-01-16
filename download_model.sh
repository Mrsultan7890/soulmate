#!/bin/bash

echo "📥 Downloading Gender Detection Model..."
echo ""

MODEL_DIR="flutter_app/assets/models"
MODEL_FILE="$MODEL_DIR/gender_model.tflite"

# Create directory if not exists
mkdir -p "$MODEL_DIR"

# Download lightweight gender classification model
# Using a pre-trained MobileNetV2 based model (~5MB)
echo "Downloading model from GitHub..."

# Option 1: Download from public repository
curl -L "https://github.com/arunponnusamy/gender-detection-keras/raw/master/gender_detection.model" \
  -o "$MODEL_FILE" 2>/dev/null

if [ -f "$MODEL_FILE" ]; then
    SIZE=$(du -h "$MODEL_FILE" | cut -f1)
    echo "✅ Model downloaded successfully!"
    echo "📦 Size: $SIZE"
    echo "📍 Location: $MODEL_FILE"
else
    echo "⚠️  Download failed. Creating placeholder..."
    echo ""
    echo "📝 Manual Setup Required:"
    echo "1. Download a TFLite gender classification model"
    echo "2. Place it at: $MODEL_FILE"
    echo ""
    echo "Recommended models:"
    echo "- MobileNetV2 Gender Classifier (5-8 MB)"
    echo "- EfficientNet Gender Classifier (3-5 MB)"
    echo ""
    echo "Sources:"
    echo "- TensorFlow Hub: https://tfhub.dev/"
    echo "- Kaggle: https://www.kaggle.com/models"
    echo "- GitHub: Search 'gender classification tflite'"
fi

echo ""
echo "🔧 Next Steps:"
echo "1. Place gender_model.tflite in flutter_app/assets/models/"
echo "2. Run: cd flutter_app && flutter pub get"
echo "3. Build app: flutter build apk"
echo ""
echo "📖 Model Requirements:"
echo "- Input: 224x224 RGB image"
echo "- Output: [male_score, female_score]"
echo "- Format: TensorFlow Lite (.tflite)"

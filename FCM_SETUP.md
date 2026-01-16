# Firebase Cloud Messaging (FCM) Setup Guide

## 🔥 Firebase Console Setup (5 minutes)

### Step 1: Create Firebase Project
1. Go to: https://console.firebase.google.com/
2. Click "Add project"
3. Project name: **HeartLink**
4. Disable Google Analytics (optional)
5. Click "Create project"

### Step 2: Add Android App
1. Click Android icon
2. Android package name: `com.heartlink.app` (from AndroidManifest.xml)
3. App nickname: HeartLink
4. Click "Register app"
5. **Download `google-services.json`**
6. Place it in: `flutter_app/android/app/google-services.json`
7. Click "Next" → "Next" → "Continue to console"

### Step 3: Get Server Key
1. Go to Project Settings (gear icon)
2. Click "Cloud Messaging" tab
3. Copy "Server key" (starts with AAAA...)
4. Save this key - needed for backend

## 📱 Flutter Setup (Already done in code)

Files created:
- ✅ `lib/services/notification_service.dart`
- ✅ `lib/services/fcm_service.dart`
- ✅ Updated `main.dart`
- ✅ Updated `pubspec.yaml`

## 🔧 Manual Steps Required

### 1. Download google-services.json
- From Firebase Console → Project Settings → Your apps
- Place in: `flutter_app/android/app/google-services.json`

### 2. Update .env file
Add Firebase server key:
```
FCM_SERVER_KEY=your_server_key_here
```

### 3. Run these commands:
```bash
cd flutter_app
flutter pub get
flutter clean
flutter run
```

## 🎯 Features Implemented

### Notifications:
- ✅ Match notifications ("It's a Match!")
- ✅ New message notifications
- ✅ Like received notifications
- ✅ Profile view notifications
- ✅ Custom sounds & vibrations
- ✅ In-app alerts
- ✅ Background notifications

### Backend:
- ✅ Send notification on match
- ✅ Send notification on new message
- ✅ Send notification on like
- ✅ FCM token management
- ✅ Automatic retry on failure

## 🧪 Testing

### Test notification manually:
```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "USER_FCM_TOKEN",
    "notification": {
      "title": "Test Match!",
      "body": "You matched with someone!"
    }
  }'
```

## 📊 Cost: $0 (FREE Forever)
- Unlimited notifications
- No credit card required
- Google handles all infrastructure

## 🆘 Troubleshooting

**Issue**: Notifications not working
**Fix**: 
1. Check google-services.json is in correct location
2. Verify FCM_SERVER_KEY in .env
3. Run `flutter clean && flutter pub get`
4. Rebuild app

**Issue**: Token not saving
**Fix**: Check database has fcm_token column

## ✅ Next Steps
1. Download google-services.json from Firebase
2. Add FCM_SERVER_KEY to .env
3. Run `flutter pub get`
4. Test notifications!

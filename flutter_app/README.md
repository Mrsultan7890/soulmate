# 💕 HeartLink - Dating App

A beautiful, production-ready dating app built with Flutter and FastAPI backend.

## ✨ Features

### 🎯 Core Features
- **User Authentication** - Secure login/register with JWT tokens
- **Profile Management** - Complete profile with photos, bio, interests
- **Smart Discovery** - Swipe cards with advanced filtering
- **Real-time Matching** - Instant match notifications
- **Live Chat** - WebSocket-based real-time messaging
- **Location-based** - Find matches nearby
- **Interests Matching** - Connect based on shared interests

### 🎨 UI/UX Features
- Beautiful gradient designs
- Smooth animations
- Card swipe functionality
- Real-time updates
- Responsive layouts
- Material Design 3

### 🔒 Safety Features
- Anti-scam detection
- Photo privacy controls
- User verification
- Report & block functionality

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.16.0 or higher)
- Dart SDK
- Android Studio / Xcode
- Backend API running (see main README)

### Installation

1. **Navigate to Flutter app directory**
```bash
cd flutter_app
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure API endpoint**
Edit `lib/utils/api_constants.dart`:
```dart
static const String baseUrl = 'http://YOUR_BACKEND_URL:8000';
```

4. **Run the app**
```bash
# For Android
flutter run

# For iOS
flutter run -d ios

# For Web
flutter run -d chrome
```

## 📱 Build for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🏗️ Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user.dart
│   ├── match.dart
│   └── message.dart
├── screens/                  # UI screens
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── register_screen.dart
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── discover_screen.dart
│   ├── matches/
│   │   └── matches_screen.dart
│   ├── chat/
│   │   └── chat_screen.dart
│   └── profile/
│       ├── profile_screen.dart
│       └── edit_profile_screen.dart
├── services/                 # Business logic
│   ├── auth_service.dart
│   ├── user_service.dart
│   ├── match_service.dart
│   └── chat_service.dart
├── widgets/                  # Reusable widgets
│   ├── user_card.dart
│   └── match_dialog.dart
└── utils/                    # Utilities
    ├── theme.dart
    └── api_constants.dart
```

## 🎨 Customization

### Colors
Edit `lib/utils/theme.dart` to customize app colors:
```dart
static const primaryColor = Color(0xFFFF6B9D);
static const secondaryColor = Color(0xFFFEC163);
```

### App Name & Icon
1. Update `pubspec.yaml`:
```yaml
name: your_app_name
```

2. Replace app icon in `assets/images/app_icon.png`

3. Run:
```bash
flutter pub run flutter_launcher_icons
```

## 🔧 Configuration

### API Endpoints
Configure in `lib/utils/api_constants.dart`:
- Base URL
- Auth endpoints
- User endpoints
- Match endpoints
- Chat endpoints

### Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):
- Internet
- Location
- Camera
- Storage

**iOS** (`ios/Runner/Info.plist`):
- NSLocationWhenInUseUsageDescription
- NSCameraUsageDescription
- NSPhotoLibraryUsageDescription

## 📦 Dependencies

### Core
- `flutter` - UI framework
- `provider` - State management
- `http` / `dio` - API calls

### UI
- `google_fonts` - Typography
- `cached_network_image` - Image caching
- `flutter_card_swiper` - Swipe cards
- `shimmer` - Loading effects
- `lottie` - Animations

### Functionality
- `shared_preferences` - Local storage
- `geolocator` - Location services
- `image_picker` - Photo selection
- `web_socket_channel` - Real-time chat
- `timeago` - Time formatting

## 🚀 GitHub Actions CI/CD

The project includes automated build workflows:

### Automatic Builds
- Triggers on push to main/master
- Builds Android APK & AAB
- Builds iOS IPA
- Uploads artifacts

### Release
- Create a tag: `git tag v1.0.0`
- Push tag: `git push origin v1.0.0`
- GitHub Actions will create a release with all builds

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Analyze code
flutter analyze
```

## 📱 Screenshots

Add screenshots in `assets/screenshots/` directory.

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License.

## 🆘 Support

For issues and questions:
- Open an issue on GitHub
- Check existing documentation
- Review API documentation

## 🎯 Roadmap

- [ ] Video chat
- [ ] Stories feature
- [ ] Advanced filters
- [ ] Premium subscription
- [ ] Push notifications
- [ ] Social media integration
- [ ] AI-powered matching

## 💡 Tips

1. **Development**: Use `flutter run` with hot reload
2. **Debugging**: Enable debug mode in API constants
3. **Performance**: Use `flutter build --profile` for profiling
4. **Testing**: Test on real devices for best results

## 🌟 Features Highlights

### Swipe Cards
Beautiful card-based UI with smooth animations for discovering potential matches.

### Real-time Chat
WebSocket-powered instant messaging with typing indicators.

### Smart Matching
Advanced algorithm considering location, interests, and preferences.

### Beautiful UI
Modern gradient designs with smooth animations and transitions.

---

Made with ❤️ using Flutter

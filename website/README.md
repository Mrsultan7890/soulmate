# HeartLink Website Assets

## Image Requirements

### 📁 `/assets/icons/` folder:
- `app-icon.png` - Small app icon (40x40px) for header
- `app-icon-large.png` - Large app icon (120x120px) for hero section
- `favicon.ico` - Website favicon (32x32px)

### 📁 `/assets/screenshots/` folder:
- `main-screen.png` - Main app screen for hero section (300x600px recommended)
- `discover.png` - Discover/Swipe screen
- `chat.png` - Chat screen
- `profile.png` - Profile screen
- `video-call.png` - Video call screen
- `games.png` - Games screen
- `feed.png` - Social feed screen

**Screenshot Requirements:**
- Size: 300x600px (phone aspect ratio)
- Format: PNG with transparent background or clean mockup
- Quality: High resolution, clear UI elements

### 📁 `/assets/` folder (root):
- `heartlink-v1.0.0.apk` - Your compiled APK file for download

## Image Tips:
1. **App Icon**: Use your pink gradient heart icon
2. **Screenshots**: Take from Android emulator or real device
3. **Mockups**: Use phone mockup generators for professional look
4. **Optimization**: Compress images for faster loading

## File Structure:
```
website/
├── index.html
├── style.css
├── script.js
└── assets/
    ├── heartlink-v1.0.0.apk
    ├── icons/
    │   ├── app-icon.png
    │   ├── app-icon-large.png
    │   └── favicon.ico
    └── screenshots/
        ├── main-screen.png
        ├── discover.png
        ├── chat.png
        ├── profile.png
        ├── video-call.png
        ├── games.png
        └── feed.png
```

## Deployment:
1. Add all images to respective folders
2. Place your APK file in `/assets/`
3. Upload entire website folder to hosting service
4. Test download functionality

## Hosting Options (Free):
- Netlify
- Vercel
- GitHub Pages
- Firebase Hosting
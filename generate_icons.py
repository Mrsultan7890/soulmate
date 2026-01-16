#!/usr/bin/env python3
import os
import subprocess

SIZES = {
    'android': {
        'mipmap-mdpi': 48, 'mipmap-hdpi': 72, 'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144, 'mipmap-xxxhdpi': 192
    },
    'ios': {
        'Icon-20': 20, 'Icon-20@2x': 40, 'Icon-20@3x': 60,
        'Icon-29': 29, 'Icon-29@2x': 58, 'Icon-29@3x': 87,
        'Icon-40': 40, 'Icon-40@2x': 80, 'Icon-40@3x': 120,
        'Icon-60@2x': 120, 'Icon-60@3x': 180,
        'Icon-76': 76, 'Icon-76@2x': 152, 'Icon-83.5@2x': 167,
        'Icon-1024': 1024
    }
}

def convert(svg, out, size):
    cmd = f"convert -background none -resize {size}x{size} {svg} {out}"
    subprocess.run(cmd, shell=True, check=True)
    print(f"✓ {out}")

svg = "app_icon.svg"
print("🎨 Generating HeartLink Icons...\n")

# Android
for folder, size in SIZES['android'].items():
    path = f"flutter_app/android/app/src/main/res/{folder}"
    os.makedirs(path, exist_ok=True)
    convert(svg, f"{path}/ic_launcher.png", size)

# iOS
ios_path = "flutter_app/ios/Runner/Assets.xcassets/AppIcon.appiconset"
os.makedirs(ios_path, exist_ok=True)
for name, size in SIZES['ios'].items():
    convert(svg, f"{ios_path}/{name}.png", size)

# Web
os.makedirs("flutter_app/web/icons", exist_ok=True)
convert(svg, "flutter_app/web/icons/Icon-512.png", 512)
convert(svg, "flutter_app/web/icons/Icon-192.png", 192)

print("\n✅ Done! Build app to see new icon.")

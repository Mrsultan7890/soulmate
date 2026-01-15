from PIL import Image, ImageDraw

sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192
}

for folder, size in sizes.items():
    img = Image.new('RGB', (size, size), color='#FF6B9D')
    img.save(f'android/app/src/main/res/{folder}/ic_launcher.png')

import os
from PIL import Image

# Resolve source icon relative to project directory
project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src_path = os.path.join(project_root, "assets", "icon", "app_icon.png")

if not os.path.exists(src_path):
    # Fallback to local path if executed from project root
    src_path = os.path.join("assets", "icon", "app_icon.png")

if not os.path.exists(src_path):
    raise FileNotFoundError(f"Source icon not found at {src_path}")

img = Image.open(src_path).convert("RGBA")

# Ensure assets/icon directory exists
icon_dir = os.path.join(project_root, "assets", "icon")
os.makedirs(icon_dir, exist_ok=True)
master_1024 = img.resize((1024, 1024), Image.Resampling.LANCZOS)
master_1024.save(os.path.join(icon_dir, "app_icon.png"), "PNG")
print(f"Saved {os.path.join(icon_dir, 'app_icon.png')}")

# Android mipmaps
android_sizes = {
    "android/app/src/main/res/mipmap-mdpi/ic_launcher.png": (48, 48),
    "android/app/src/main/res/mipmap-hdpi/ic_launcher.png": (72, 72),
    "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": (96, 96),
    "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": (144, 144),
    "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": (192, 192),
}

for rel_path, size in android_sizes.items():
    full_path = os.path.join(project_root, rel_path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    resized = img.resize(size, Image.Resampling.LANCZOS)
    resized.save(full_path, "PNG")
    print(f"Generated Android icon: {rel_path} ({size[0]}x{size[1]})")

# Web icons
web_sizes = {
    "web/icons/Icon-192.png": (192, 192),
    "web/icons/Icon-512.png": (512, 512),
    "web/icons/Icon-maskable-192.png": (192, 192),
    "web/icons/Icon-maskable-512.png": (512, 512),
    "web/favicon.png": (64, 64),
}

for rel_path, size in web_sizes.items():
    full_path = os.path.join(project_root, rel_path)
    os.makedirs(os.path.dirname(full_path), exist_ok=True)
    resized = img.resize(size, Image.Resampling.LANCZOS)
    resized.save(full_path, "PNG")
    print(f"Generated Web icon: {rel_path} ({size[0]}x{size[1]})")

# iOS icons
ios_dir = os.path.join(project_root, "ios", "Runner", "Assets.xcassets", "AppIcon.appiconset")
if os.path.exists(ios_dir):
    ios_sizes = {
        "Icon-App-1024x1024@1x.png": (1024, 1024),
        "Icon-App-20x20@1x.png": (20, 20),
        "Icon-App-20x20@2x.png": (40, 40),
        "Icon-App-20x20@3x.png": (60, 60),
        "Icon-App-29x29@1x.png": (29, 29),
        "Icon-App-29x29@2x.png": (58, 58),
        "Icon-App-29x29@3x.png": (87, 87),
        "Icon-App-40x40@1x.png": (40, 40),
        "Icon-App-40x40@2x.png": (80, 80),
        "Icon-App-40x40@3x.png": (120, 120),
        "Icon-App-60x60@2x.png": (120, 120),
        "Icon-App-60x60@3x.png": (180, 180),
        "Icon-App-76x76@1x.png": (76, 76),
        "Icon-App-76x76@2x.png": (152, 152),
        "Icon-App-83.5x83.5@2x.png": (167, 167),
    }
    for file_name, size in ios_sizes.items():
        full_path = os.path.join(ios_dir, file_name)
        resized = img.resize(size, Image.Resampling.LANCZOS)
        resized.save(full_path, "PNG")
        print(f"Generated iOS icon: {file_name} ({size[0]}x{size[1]})")

print("All app icons generated successfully!")

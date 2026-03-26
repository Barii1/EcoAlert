# App Icon Setup

To generate your custom app icon:

## Quick Setup (Recommended)

1. Place your 1024x1024 PNG icon in this folder as `app_icon.png`
2. Run: `flutter pub run flutter_launcher_icons`
3. The icons will be automatically generated for Android and iOS

## Manual Icon Creation

If you need to create an icon from scratch, you can:

1. Use an online icon generator (e.g., appicon.co)
2. Design in Figma/Photoshop with these specs:
   - Size: 1024x1024px
   - Format: PNG with transparency
   - Design: Green gradient background (#2E7D32 to #66BB6A)
   - Icon: White eco leaf symbol with orange alert badge

## Current Configuration

The `pubspec.yaml` is already configured with:
- Adaptive icon background: #2E7D32 (green)
- Android and iOS icon generation enabled

## For Testing

If you want to quickly test with a placeholder:
1. Create any 1024x1024 PNG image
2. Name it `app_icon.png` and place it here
3. Run `flutter pub run flutter_launcher_icons`
4. Rebuild your app

The app will use this icon on the home screen and in the app drawer.

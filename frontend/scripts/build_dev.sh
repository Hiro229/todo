#!/bin/bash
# Development Build Script

echo "Building Flutter app for Development environment..."

flutter clean
flutter pub get

# Android Development Build
echo "Building Android APK for Development..."
flutter build apk --dart-define=FLUTTER_ENV=development --debug --target-platform android-arm64

# iOS Development Build (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Building iOS app for Development..."
    flutter build ios --dart-define=FLUTTER_ENV=development --debug --no-codesign
fi

# Web Development Build
echo "Building Web app for Development..."
flutter build web --dart-define=FLUTTER_ENV=development --web-renderer html

echo "Development build completed!"
#!/bin/bash
# Staging Build Script

echo "Building Flutter app for Staging environment..."

flutter clean
flutter pub get

# Android Staging Build
echo "Building Android APK for Staging..."
flutter build apk --dart-define=FLUTTER_ENV=staging --release --target-platform android-arm64 --build-name=1.0.0-staging

# iOS Staging Build (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Building iOS app for Staging..."
    flutter build ios --dart-define=FLUTTER_ENV=staging --release --build-name=1.0.0-staging
fi

# Web Staging Build
echo "Building Web app for Staging..."
flutter build web --dart-define=FLUTTER_ENV=staging --web-renderer html --base-href /

echo "Staging build completed!"
#!/bin/bash
# Production Build Script

echo "Building Flutter app for Production environment..."

flutter clean
flutter pub get

# Android Production Build
echo "Building Android APK for Production..."
flutter build apk --dart-define=FLUTTER_ENV=production --release --target-platform android-arm64 --build-name=1.0.0

echo "Building Android App Bundle for Production..."
flutter build appbundle --dart-define=FLUTTER_ENV=production --release --build-name=1.0.0

# iOS Production Build (macOS only)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Building iOS app for Production..."
    flutter build ios --dart-define=FLUTTER_ENV=production --release --build-name=1.0.0
fi

# Web Production Build
echo "Building Web app for Production..."
flutter build web --dart-define=FLUTTER_ENV=production --web-renderer html --base-href /

echo "Production build completed!"
echo "APK: build/app/outputs/flutter-apk/app-release.apk"
echo "App Bundle: build/app/outputs/bundle/release/app-release.aab"
echo "Web: build/web/"
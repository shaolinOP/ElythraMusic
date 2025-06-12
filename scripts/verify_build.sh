#!/bin/bash

# Elythra Music Build Verification Script
# This script verifies Firebase configuration and tests the build

echo "🔥 Elythra Music - Build Verification"
echo "====================================="
echo ""

# Check Firebase configuration
echo "📋 Checking Firebase Configuration..."
if [ -f "android/app/google-services.json" ]; then
    echo "✅ google-services.json: FOUND"
    PROJECT_ID=$(grep 'project_id' android/app/google-services.json | cut -d'"' -f4)
    PACKAGE_NAME=$(grep 'package_name' android/app/google-services.json | head -1 | cut -d'"' -f4)
    CLIENT_COUNT=$(grep -c 'client_id' android/app/google-services.json)
    
    echo "  📁 Project ID: $PROJECT_ID"
    echo "  📦 Package Name: $PACKAGE_NAME"
    echo "  🔑 Client IDs: $CLIENT_COUNT configured"
else
    echo "❌ google-services.json: NOT FOUND"
    echo "   Please place the file in android/app/google-services.json"
    exit 1
fi

echo ""

# Check Flutter
echo "📱 Checking Flutter..."
if command -v flutter &> /dev/null; then
    echo "✅ Flutter: FOUND"
    flutter --version | head -1
else
    echo "❌ Flutter: NOT FOUND"
    echo "   Please install Flutter: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo ""

# Check dependencies
echo "📦 Checking Dependencies..."
if [ -f "pubspec.yaml" ]; then
    echo "✅ pubspec.yaml: FOUND"
    echo "🔄 Running flutter pub get..."
    flutter pub get
    if [ $? -eq 0 ]; then
        echo "✅ Dependencies: RESOLVED"
    else
        echo "❌ Dependencies: FAILED"
        exit 1
    fi
else
    echo "❌ pubspec.yaml: NOT FOUND"
    exit 1
fi

echo ""

# Test build
echo "🔨 Testing Build..."
echo "🔄 Running flutter build apk --debug..."
flutter build apk --debug

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 BUILD SUCCESSFUL!"
    echo "========================"
    echo "✅ Firebase configuration: WORKING"
    echo "✅ Dependencies: RESOLVED"
    echo "✅ Build: SUCCESSFUL"
    echo ""
    echo "📱 APK Location: build/app/outputs/flutter-apk/app-debug.apk"
    echo ""
    echo "🚀 Ready for testing!"
else
    echo ""
    echo "❌ BUILD FAILED!"
    echo "==============="
    echo "Please check the error messages above and fix any issues."
    exit 1
fi
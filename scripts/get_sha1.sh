#!/bin/bash

# Script to get SHA-1 fingerprint for Firebase setup
# This is needed for Google Sign-In configuration

echo "🔑 Getting SHA-1 Certificate Fingerprint for Firebase"
echo "=================================================="

# Check if debug keystore exists
if [ ! -f ~/.android/debug.keystore ]; then
    echo "⚠️  Debug keystore not found. Creating one..."
    mkdir -p ~/.android
    keytool -genkey -v -keystore ~/.android/debug.keystore \
        -storepass android -alias androiddebugkey -keypass android \
        -keyalg RSA -keysize 2048 -validity 10000 \
        -dname "CN=Android Debug,O=Android,C=US"
    echo "✅ Debug keystore created"
fi

echo ""
echo "📋 SHA-1 Fingerprint for Firebase Console:"
echo "=========================================="

# Extract just the SHA-1 fingerprint
SHA1=$(keytool -list -v -keystore ~/.android/debug.keystore \
    -alias androiddebugkey -storepass android -keypass android 2>/dev/null | \
    grep "SHA1:" | cut -d' ' -f2-)

echo "SHA-1: $SHA1"
echo ""
echo "📝 Copy this SHA-1 fingerprint to Firebase Console:"
echo "   Project Settings > Your apps > Android app > SHA certificate fingerprints"
echo ""
echo "🔗 Firebase Console: https://console.firebase.google.com"
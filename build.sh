#!/bin/bash
set -e

echo "🔥 LÖVE APK compiler setup"

# Check Java
java -version

# Install basic tools only
sudo apt-get update
sudo apt-get install -y git zip unzip

# Download LÖVE Android source if missing
if [ ! -d love-android ]; then
    echo "📥 Downloading LÖVE Android..."
    git clone --depth 1 --recursive https://github.com/love2d/love-android.git
fi

# Package THIS repository as game.love
echo "📦 Packaging game..."
rm -f game.love game.apk
zip -r game.love . \
    -x ".git/*" \
    -x "love-android/*" \
    -x "game.love" \
    -x "game.apk"

# Put game into Android project
mkdir -p love-android/app/src/embed/assets
cp game.love love-android/app/src/embed/assets/game.love

# Build
echo "🔨 Compiling APK..."
cd love-android
chmod +x gradlew
./gradlew --no-daemon assembleEmbedNoRecordRelease

# Find APK
APK=$(find app/build/outputs -type f -name "*.apk" | head -n 1)

if [ -z "$APK" ]; then
    echo "❌ Build finished but APK wasn't found"
    exit 1
fi

cp "$APK" ../game.apk

echo ""
echo "================================"
echo "🔥 APK READY!"
echo "📦 game.apk"
echo "================================"

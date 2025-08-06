#!/bin/bash

# Mac 데이터 클리너 DMG 빌드 스크립트

set -e

APP_NAME="MacDataCleaner"
DMG_NAME="Mac 데이터 클리너"
BUILD_DIR="build"
DMG_DIR="dmg_temp"
BACKGROUND_IMG="dmg_background.png"

echo "🧹 Mac 데이터 클리너 DMG 빌드 시작..."

# 이전 빌드 정리
rm -rf "$BUILD_DIR"
rm -rf "$DMG_DIR"
rm -f "${DMG_NAME}.dmg"

# Xcode로 앱 빌드
echo "📱 앱 빌드 중..."

# 모든 Swift 파일 수동 컴파일
echo "🔧 Swift 파일 수동 컴파일..."
SWIFT_FILES=(
    "${APP_NAME}/${APP_NAME}/DataScanner.swift"
    "${APP_NAME}/${APP_NAME}/CleanupManager.swift"
    "${APP_NAME}/${APP_NAME}/ContentView.swift"
    "${APP_NAME}/${APP_NAME}/MacDataCleanerApp.swift"
)

mkdir -p "$BUILD_DIR/manual"

swiftc -target arm64-apple-macos14.0 \
       -sdk /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk \
       -emit-executable \
       -o "$BUILD_DIR/manual/MacDataCleaner" \
       "${SWIFT_FILES[@]}"

if [ $? -eq 0 ]; then
    echo "✅ 수동 컴파일 성공"
    # 수동으로 앱 번들 생성
    mkdir -p "$BUILD_DIR/manual/MacDataCleaner.app/Contents/MacOS"
    mkdir -p "$BUILD_DIR/manual/MacDataCleaner.app/Contents/Resources"
    
    cp "$BUILD_DIR/manual/MacDataCleaner" "$BUILD_DIR/manual/MacDataCleaner.app/Contents/MacOS/"
    
    # Info.plist 생성
    cat > "$BUILD_DIR/manual/MacDataCleaner.app/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MacDataCleaner</string>
    <key>CFBundleIdentifier</key>
    <string>com.mactaphine.MacDataCleaner</string>
    <key>CFBundleName</key>
    <string>Mac 데이터 클리너</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
</dict>
</plist>
EOF
    
    APP_PATH="$BUILD_DIR/manual/MacDataCleaner.app"
else
    echo "❌ 수동 컴파일 실패, Xcode 빌드 시도..."
    xcodebuild -project "${APP_NAME}/${APP_NAME}.xcodeproj" \
               -scheme "$APP_NAME" \
               -configuration Release \
               -derivedDataPath "$BUILD_DIR" \
               build
    
    # 빌드된 앱 찾기
    APP_PATH=$(find "$BUILD_DIR" -name "${APP_NAME}.app" -type d | head -1)
fi

if [ ! -d "$APP_PATH" ]; then
    echo "❌ 앱 빌드 실패!"
    exit 1
fi

echo "✅ 앱 빌드 완료: $APP_PATH"

# DMG 임시 디렉토리 생성
mkdir -p "$DMG_DIR"

# 앱을 DMG 디렉토리에 복사
cp -R "$APP_PATH" "$DMG_DIR/"

# Applications 폴더 심볼릭 링크 생성
ln -s /Applications "$DMG_DIR/Applications"

# DMG 배경 이미지 생성 (간단한 텍스트 기반)
echo "🎨 DMG 배경 설정..."

# DMG 생성
echo "📦 DMG 생성 중..."
hdiutil create -srcfolder "$DMG_DIR" \
               -volname "$DMG_NAME" \
               -fs HFS+ \
               -fsargs "-c c=64,a=16,e=16" \
               -format UDRW \
               -size 100m \
               "${DMG_NAME}_temp.dmg"

# DMG 마운트
echo "🔧 DMG 설정 중..."
MOUNT_DIR=$(hdiutil attach "${DMG_NAME}_temp.dmg" | grep Volumes | cut -f 3)

if [ ! -d "$MOUNT_DIR" ]; then
    echo "❌ DMG 마운트 실패!"
    exit 1
fi

# DMG 창 설정 (AppleScript 사용)
osascript <<EOF
tell application "Finder"
    tell disk "$DMG_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 600, 400}
        set position of item "${APP_NAME}.app" of container window to {150, 200}
        set position of item "Applications" of container window to {350, 200}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# DMG 언마운트
hdiutil detach "$MOUNT_DIR"

# 최종 DMG 생성 (압축)
echo "🗜️ DMG 압축 중..."
hdiutil convert "${DMG_NAME}_temp.dmg" \
                -format UDZO \
                -imagekey zlib-level=9 \
                -o "${DMG_NAME}.dmg"

# 임시 파일 정리
rm -f "${DMG_NAME}_temp.dmg"
rm -rf "$BUILD_DIR"
rm -rf "$DMG_DIR"

echo "✅ DMG 생성 완료: ${DMG_NAME}.dmg"
echo "🎉 빌드 성공!"

# DMG 크기 표시
DMG_SIZE=$(du -h "${DMG_NAME}.dmg" | cut -f1)
echo "📦 DMG 크기: $DMG_SIZE"
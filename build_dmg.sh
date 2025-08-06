#!/bin/bash

# Mactaphine DMG 빌드 스크립트
APP_NAME="Mactaphine"
BUILD_DIR="build"
MANUAL_BUILD_DIR="$BUILD_DIR/manual"
DMG_NAME="$APP_NAME.dmg"
TEMP_DMG_NAME="${APP_NAME}_temp.dmg"

echo "🧹 $APP_NAME DMG 빌드 시작..."

# 빌드 디렉토리 정리
rm -rf "$BUILD_DIR"
mkdir -p "$MANUAL_BUILD_DIR"

echo "📱 앱 빌드 중..."

# Swift 파일 수동 컴파일
echo "🔧 Swift 파일 수동 컴파일..."

SWIFT_FILES=(
    "MacDataCleaner/MacDataCleaner/DataScanner.swift"
    "MacDataCleaner/MacDataCleaner/CleanupManager.swift"
    "MacDataCleaner/MacDataCleaner/ContentView.swift"
    "MacDataCleaner/MacDataCleaner/MacDataCleanerApp.swift"
)

# Swift 컴파일
swiftc -target x86_64-apple-macos14.0 \
    -sdk $(xcrun --show-sdk-path --sdk macosx) \
    -I $(xcrun --show-sdk-path --sdk macosx)/System/Library/Frameworks \
    -framework SwiftUI \
    -framework AppKit \
    -framework Foundation \
    -framework FileProvider \
    -o "$MANUAL_BUILD_DIR/$APP_NAME" \
    "${SWIFT_FILES[@]}"

if [ $? -eq 0 ]; then
    echo "✅ 수동 컴파일 성공"
else
    echo "❌ 수동 컴파일 실패"
    exit 1
fi

# .app 번들 생성
APP_BUNDLE="$MANUAL_BUILD_DIR/$APP_NAME.app"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 실행 파일 복사
cp "$MANUAL_BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

# Info.plist 생성
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.mactaphine.app</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleSignature</key>
    <string>????</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# PkgInfo 생성
echo "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

# 실행 권한 설정
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

echo "✅ 앱 빌드 완료: $APP_BUNDLE"

# DMG 생성
echo "🎨 DMG 배경 설정..."

# 임시 DMG 생성
echo "📦 DMG 생성 중..."
hdiutil create -size 100m -fs HFS+ -volname "$APP_NAME" -attach "$TEMP_DMG_NAME"

# 앱 복사
cp -R "$APP_BUNDLE" "/Volumes/$APP_NAME/"

# Applications 폴더 심볼릭 링크 생성
ln -s /Applications "/Volumes/$APP_NAME/Applications"

# DMG 분리
hdiutil detach "/Volumes/$APP_NAME"

# DMG 설정
echo "🔧 DMG 설정 중..."
hdiutil convert "$TEMP_DMG_NAME" -format UDZO -o "$DMG_NAME"

# 임시 파일 정리
rm "$TEMP_DMG_NAME"

# DMG 압축
echo "🗜️ DMG 압축 중..."
hdiutil convert "$DMG_NAME" -format UDZO -o "$DMG_NAME" -ov

echo "✅ DMG 생성 완료: $DMG_NAME"
echo "🎉 빌드 성공!"
echo "📦 DMG 크기: $(du -h "$DMG_NAME" | cut -f1)"
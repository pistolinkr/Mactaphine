#!/bin/bash

# Mactaphine GitHub Release 자동 생성 스크립트
REPO="pistolinkr/Mactaphine"
VERSION="v1.0.0"
TAG="v1.0.0"
TITLE="Mactaphine v1.0.0 🎉"
DMG_FILE="Mactaphine.dmg"

echo "🚀 Mactaphine GitHub Release 생성 시작..."

# GitHub CLI 로그인 확인
if ! gh auth status >/dev/null 2>&1; then
    echo "❌ GitHub CLI 로그인이 필요합니다."
    echo "다음 명령어로 로그인하세요:"
    echo "gh auth login"
    exit 1
fi

# DMG 파일 존재 확인
if [ ! -f "$DMG_FILE" ]; then
    echo "❌ $DMG_FILE 파일을 찾을 수 없습니다."
    echo "먼저 앱을 빌드하세요: ./build_dmg.sh"
    exit 1
fi

# 릴리즈 노트 읽기
if [ -f "RELEASE_NOTES_EN.md" ]; then
    RELEASE_NOTES=$(cat RELEASE_NOTES_EN.md)
else
    RELEASE_NOTES="Mactaphine v1.0.0 릴리즈

## 🚀 새로운 기능
- 전문적인 설정 패널 추가
- 다국어 지원 (한국어, 영어, 일본어, 중국어)
- 스캔 범위 커스터마이징
- 테마 설정 (라이트/다크/시스템)
- 자동 스캔 옵션

## 📦 다운로드
- macOS: Mactaphine.dmg (264KB)
- 네이티브 Swift 앱
- Apple Silicon + Intel 지원"
fi

echo "📝 릴리즈 정보:"
echo "  태그: $TAG"
echo "  제목: $TITLE"
echo "  파일: $DMG_FILE"
echo ""

# 기존 태그가 있는지 확인
if gh release view "$TAG" >/dev/null 2>&1; then
    echo "⚠️  태그 $TAG가 이미 존재합니다. 삭제하시겠습니까? (y/N)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo "🗑️  기존 릴리즈 삭제 중..."
        gh release delete "$TAG" --yes
    else
        echo "❌ 릴리즈 생성이 취소되었습니다."
        exit 1
    fi
fi

# 릴리즈 생성
echo "📦 GitHub 릴리즈 생성 중..."
gh release create "$TAG" \
    --title "$TITLE" \
    --notes "$RELEASE_NOTES" \
    --repo "$REPO" \
    "$DMG_FILE"

if [ $? -eq 0 ]; then
    echo "✅ 릴리즈가 성공적으로 생성되었습니다!"
    echo "🌐 릴리즈 URL: https://github.com/$REPO/releases/tag/$TAG"
    echo "📥 다운로드 URL: https://github.com/$REPO/releases/download/$TAG/$DMG_FILE"
else
    echo "❌ 릴리즈 생성에 실패했습니다."
    exit 1
fi

echo ""
echo "🎉 Mactaphine v1.0.0 릴리즈가 완료되었습니다!" 
# Mac Data Cleaner 🧹 | Mac 데이터 클리너

A dedicated Mac data cleaning application designed specifically for system data management.

시스템 데이터만을 위한 전용 맥 데이터 정리 애플리케이션입니다.

[한국어](#한국어) | [English](#english)

---

## English

### Features

- **System Cache Cleaning**: Clean `/System/Library/Caches`, `/Library/Caches`
- **User Cache Cleaning**: Clean application caches in `~/Library/Caches`
- **Log File Cleaning**: Clean system and user log files (files older than 7 days)
- **Empty Trash**: Complete trash cleanup
- **Application Data**: Clean large application support files
- **Browser Cache**: Clean Safari, Chrome, Firefox caches
- **Temporary Files**: Clean `/tmp`, `/var/tmp` and other temporary files

### Safety Features

- ✅ Protects critical system files
- ✅ Preserves user data (documents, photos, etc.)
- ✅ Confirmation dialog before cleanup
- ✅ Selective cleanup options
- ✅ Preserves browser bookmarks/passwords

### System Requirements

- macOS 14.0 or later
- 64-bit Intel or Apple Silicon Mac

### Building

#### 1. Build with Xcode
```bash
open MacDataCleaner/MacDataCleaner.xcodeproj
# Run Product > Build in Xcode
```

#### 2. Generate DMG
```bash
./build_dmg.sh
```

Install the generated `Mac 데이터 클리너.dmg` file.

### Usage

1. The app automatically starts system scanning when launched
2. Check data to clean by category in the left sidebar
3. Select items you want to clean
4. Click "정리 시작" (Start Cleanup) button to begin cleanup
5. Click "정리 시작" (Start Cleanup) in the confirmation dialog to delete selected data

### Important Notice

⚠️ **This app deletes system data. Please verify before cleanup.**

- Deleted data cannot be recovered
- Important application settings may be reset
- Browser login sessions may be cleared

### License

MIT License

### Contributing

Please submit bug reports or feature requests through Issues.

---

## 한국어

### 주요 기능

- **시스템 캐시 정리**: `/System/Library/Caches`, `/Library/Caches` 정리
- **사용자 캐시 정리**: `~/Library/Caches` 내 애플리케이션 캐시 정리
- **로그 파일 정리**: 시스템 및 사용자 로그 파일 정리 (7일 이상 된 파일만)
- **휴지통 비우기**: 완전한 휴지통 정리
- **애플리케이션 데이터**: 대용량 애플리케이션 지원 파일 정리
- **브라우저 캐시**: Safari, Chrome, Firefox 캐시 정리
- **임시 파일**: `/tmp`, `/var/tmp` 등 임시 파일 정리

### 안전 기능

- ✅ 중요한 시스템 파일 보호
- ✅ 사용자 데이터 보존 (문서, 사진 등)
- ✅ 정리 전 확인 창
- ✅ 선택적 정리 가능
- ✅ 브라우저 북마크/비밀번호 보존

### 시스템 요구사항

- macOS 14.0 이상
- 64비트 Intel 또는 Apple Silicon Mac

### 빌드 방법

#### 1. Xcode에서 빌드
```bash
open MacDataCleaner/MacDataCleaner.xcodeproj
# Xcode에서 Product > Build 실행
```

#### 2. DMG 생성
```bash
./build_dmg.sh
```

생성된 `Mac 데이터 클리너.dmg` 파일을 실행하여 설치할 수 있습니다.

### 사용법

1. 앱을 실행하면 자동으로 시스템 스캔이 시작됩니다
2. 좌측 사이드바에서 카테고리별로 정리할 데이터를 확인할 수 있습니다
3. 정리하고 싶은 항목들을 선택합니다
4. "정리 시작" 버튼을 클릭하여 정리를 시작합니다
5. 확인 창에서 "정리 시작"을 클릭하면 선택된 데이터가 삭제됩니다

### 주의사항

⚠️ **이 앱은 시스템 데이터를 삭제합니다. 정리 전에 반드시 확인하세요.**

- 삭제된 데이터는 복구할 수 없습니다
- 중요한 애플리케이션 설정이 초기화될 수 있습니다
- 브라우저 로그인 상태가 해제될 수 있습니다

### 라이선스

MIT License

### 기여하기

버그 리포트나 기능 제안은 Issues를 통해 해주세요.

---

**⚡ Fast and safe Mac system cleanup experience! | 빠르고 안전한 Mac 시스템 정리를 경험해보세요!**
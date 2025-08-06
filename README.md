# Mac Data Cleaner 🧹 | Mac 데이터 클리너

A dedicated Mac data cleaning application designed specifically for system data management.

시스템 데이터만을 위한 전용 맥 데이터 정리 애플리케이션입니다.

 | [English](#english)[한국어](#한국어) | [中文](#中文) | [日本語](#日本語)

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

## 中文

### 主要功能

- **系统缓存清理**: 清理 `/System/Library/Caches`, `/Library/Caches`
- **用户缓存清理**: 清理 `~/Library/Caches` 中的应用程序缓存
- **日志文件清理**: 清理系统和用户日志文件（仅清理7天以上的文件）
- **清空废纸篓**: 完全清空废纸篓
- **应用程序数据**: 清理大型应用程序支持文件
- **浏览器缓存**: 清理 Safari、Chrome、Firefox 缓存
- **临时文件**: 清理 `/tmp`、`/var/tmp` 等临时文件

### 安全功能

- ✅ 保护重要系统文件
- ✅ 保留用户数据（文档、照片等）
- ✅ 清理前确认对话框
- ✅ 选择性清理选项
- ✅ 保留浏览器书签/密码

### 系统要求

- macOS 14.0 或更高版本
- 64位 Intel 或 Apple Silicon Mac

### 构建方法

#### 1. 使用 Xcode 构建
```bash
open MacDataCleaner/MacDataCleaner.xcodeproj
# 在 Xcode 中运行 Product > Build
```

#### 2. 生成 DMG
```bash
./build_dmg.sh
```

安装生成的 `Mac 데이터 클리너.dmg` 文件。

### 使用方法

1. 启动应用程序时会自动开始系统扫描
2. 在左侧边栏中按类别查看要清理的数据
3. 选择要清理的项目
4. 点击"정리 시작"（开始清理）按钮开始清理
5. 在确认对话框中点击"정리 시작"（开始清理）删除选定的数据

### 重要提示

⚠️ **此应用程序会删除系统数据。请在清理前验证。**

- 已删除的数据无法恢复
- 重要的应用程序设置可能会被重置
- 浏览器登录会话可能会被清除

### 许可证

MIT License

### 贡献

请通过 Issues 提交错误报告或功能请求。

---

## 日本語

### 主な機能

- **システムキャッシュクリーニング**: `/System/Library/Caches`, `/Library/Caches` をクリーニング
- **ユーザーキャッシュクリーニング**: `~/Library/Caches` 内のアプリケーションキャッシュをクリーニング
- **ログファイルクリーニング**: システムおよびユーザーログファイルをクリーニング（7日以上経過したファイルのみ）
- **ゴミ箱を空にする**: 完全なゴミ箱クリーニング
- **アプリケーションデータ**: 大容量アプリケーションサポートファイルをクリーニング
- **ブラウザキャッシュ**: Safari、Chrome、Firefox キャッシュをクリーニング
- **一時ファイル**: `/tmp`、`/var/tmp` などの一時ファイルをクリーニング

### 安全機能

- ✅ 重要なシステムファイルを保護
- ✅ ユーザーデータを保持（ドキュメント、写真など）
- ✅ クリーニング前の確認ダイアログ
- ✅ 選択的クリーニングオプション
- ✅ ブラウザブックマーク/パスワードを保持

### システム要件

- macOS 14.0 以降
- 64ビット Intel または Apple Silicon Mac

### ビルド方法

#### 1. Xcode でビルド
```bash
open MacDataCleaner/MacDataCleaner.xcodeproj
# Xcode で Product > Build を実行
```

#### 2. DMG 生成
```bash
./build_dmg.sh
```

生成された `Mac 데이터 클리너.dmg` ファイルをインストールしてください。

### 使用方法

1. アプリを起動すると、自動的にシステムスキャンが開始されます
2. 左サイドバーでカテゴリ別にクリーニングするデータを確認できます
3. クリーニングしたい項目を選択します
4. "정리 시작"（クリーニング開始）ボタンをクリックしてクリーニングを開始します
5. 確認ダイアログで"정리 시작"（クリーニング開始）をクリックして選択されたデータを削除します

### 重要な注意事項

⚠️ **このアプリはシステムデータを削除します。クリーニング前に必ず確認してください。**

- 削除されたデータは復元できません
- 重要なアプリケーション設定がリセットされる可能性があります
- ブラウザのログインセッションがクリアされる可能性があります

### ライセンス

MIT License

### 貢献

バグレポートや機能リクエストは Issues を通じて提出してください。

---

**⚡ Fast and safe Mac system cleanup experience! | 빠르고 안전한 Mac 시스템 정리를 경험해보세요! | 快速安全的 Mac 系统清理体验！| 高速で安全な Mac システムクリーニング体験！**
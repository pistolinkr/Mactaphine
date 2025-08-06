import Foundation
import SwiftUI

// MARK: - Settings Models
struct AppSettings: Codable {
    var language: Language = .korean
    var scanCategories: Set<CleanupCategory> = Set(CleanupCategory.allCases)
    var maxFileSize: Int64 = 1_000_000_000 // 1GB
    var autoScanOnLaunch: Bool = true
    var showConfirmationDialog: Bool = true
    var scanHiddenFiles: Bool = false
    var excludeSystemFiles: Bool = true
    var customScanPaths: [String] = []
    var theme: AppTheme = .system
}

enum Language: String, CaseIterable, Codable {
    case korean = "ko"
    case english = "en"
    case japanese = "ja"
    case chinese = "zh"
    
    var displayName: String {
        switch self {
        case .korean: return "한국어"
        case .english: return "English"
        case .japanese: return "日本語"
        case .chinese: return "中文"
        }
    }
    
    var flag: String {
        switch self {
        case .korean: return "🇰🇷"
        case .english: return "🇺🇸"
        case .japanese: return "🇯🇵"
        case .chinese: return "🇨🇳"
        }
    }
}

enum AppTheme: String, CaseIterable, Codable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "라이트"
        case .dark: return "다크"
        case .system: return "시스템"
        }
    }
    
    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "gear"
        }
    }
}

// MARK: - CleanupItem
struct CleanupItem: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: Int64
    let category: CleanupCategory
    let lastModified: Date
    let riskLevel: RiskLevel
    var isSelected: Bool = false
    var description: String = ""
    
    enum RiskLevel: String, CaseIterable {
        case safe = "안전"
        case medium = "주의"
        case high = "위험"
        
        var color: Color {
            switch self {
            case .safe: return .green
            case .medium: return .orange
            case .high: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .safe: return "checkmark.shield"
            case .medium: return "exclamationmark.shield"
            case .high: return "xmark.shield"
            }
        }
    }
}

// MARK: - CleanupCategory
enum CleanupCategory: String, CaseIterable, Identifiable, Codable {
    case systemCache = "시스템 캐시"
    case userCache = "사용자 캐시"
    case logs = "로그 파일"
    case downloads = "다운로드"
    case trash = "휴지통"
    case applications = "응용프로그램 캐시"
    case browser = "브라우저 데이터"
    case temp = "임시 파일"
    case largeFiles = "대용량 파일"
    case duplicates = "중복 파일"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .systemCache: return "gearshape.2"
        case .userCache: return "person.crop.circle.fill"
        case .logs: return "doc.text.below.ecg"
        case .downloads: return "arrow.down.circle.fill"
        case .trash: return "trash.fill"
        case .applications: return "app.badge"
        case .browser: return "globe"
        case .temp: return "clock.arrow.circlepath"
        case .largeFiles: return "doc.badge.plus"
        case .duplicates: return "doc.on.doc"
        }
    }
    
    var color: Color {
        switch self {
        case .systemCache: return .blue
        case .userCache: return .green
        case .logs: return .orange
        case .downloads: return .purple
        case .trash: return .red
        case .applications: return .cyan
        case .browser: return .indigo
        case .temp: return .yellow
        case .largeFiles: return .pink
        case .duplicates: return .mint
        }
    }
    
    var description: String {
        switch self {
        case .systemCache: return "시스템 임시 파일과 캐시"
        case .userCache: return "사용자 앱 캐시 데이터"
        case .logs: return "시스템 및 앱 로그 파일"
        case .downloads: return "다운로드 폴더의 파일"
        case .trash: return "휴지통 내용"
        case .applications: return "앱별 임시 데이터"
        case .browser: return "브라우저 캐시 및 기록"
        case .temp: return "임시 파일 및 폴더"
        case .largeFiles: return "1GB 이상 대용량 파일"
        case .duplicates: return "중복된 파일들"
        }
    }
}

// MARK: - DataScanner
class DataScanner: ObservableObject {
    @Published var cleanupItems: [CleanupItem] = []
    @Published var isScanning = false
    @Published var searchText = ""
    @Published var sortOption = SortOption.size
    @Published var showOnlySafe = false
    @Published var settings = AppSettings()
    @Published var scanProgress = 0.0
    @Published var itemsByCategory: [CleanupCategory: [CleanupItem]] = [:]
    @Published var selectedSize: Int64 = 0
    @Published var totalSize: Int64 = 0
    
    private let fileManager = FileManager.default
    private let settingsKey = "MactaphineSettings"
    
    enum SortOption: String, CaseIterable {
        case size = "크기"
        case name = "이름"
        case date = "날짜"
        case category = "카테고리"
    }
    
    init() {
        loadSettings()
    }
    
    // MARK: - Settings Management
    func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: settingsKey),
           let settings = try? JSONDecoder().decode(AppSettings.self, from: data) {
            self.settings = settings
        }
    }
    
    func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }
    
    func resetSettings() {
        settings = AppSettings()
        saveSettings()
    }
    
    // MARK: - Scanning Methods
    func scanForCleanupItems() {
        guard !isScanning else { return }
        
        isScanning = true
        cleanupItems.removeAll()
        scanProgress = 0.0
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            var allItems: [CleanupItem] = []
            let categories = Array(self.settings.scanCategories)
            
            for (index, category) in categories.enumerated() {
                if Task.isCancelled { break }
                
                let items = self.scanCategory(category)
                allItems.append(contentsOf: items)
                
                DispatchQueue.main.async {
                    self.scanProgress = Double(index + 1) / Double(categories.count)
                }
            }
            
            DispatchQueue.main.async {
                self.cleanupItems = allItems
                self.isScanning = false
                self.scanProgress = 1.0
                self.updateSizes()
                self.groupItemsByCategory()
            }
        }
    }
    
    private func scanCategory(_ category: CleanupCategory) -> [CleanupItem] {
        var items: [CleanupItem] = []
        
        switch category {
        case .trash:
            items = scanTrash()
        case .userCache:
            items = scanUserCache()
        case .temp:
            items = scanTempFiles()
        case .logs:
            items = scanLogFiles()
        case .browser:
            items = scanBrowserData()
        case .downloads:
            items = scanDownloads()
        case .systemCache:
            items = scanSystemCache()
        case .applications:
            items = scanApplications()
        case .largeFiles:
            items = scanLargeFiles()
        case .duplicates:
            items = scanDuplicates()
        }
        
        return items
    }
    
    // MARK: - Category Scanning Methods
    private func scanTrash() -> [CleanupItem] {
        let trashURL = fileManager.urls(for: .trashDirectory, in: .userDomainMask).first
        return scanDirectory(trashURL?.path, category: .trash)
    }
    
    private func scanUserCache() -> [CleanupItem] {
        let cacheURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
        return scanDirectory(cacheURL?.path, category: .userCache)
    }
    
    private func scanTempFiles() -> [CleanupItem] {
        let tempURL = fileManager.urls(for: .itemReplacementDirectory, in: .userDomainMask).first
        return scanDirectory(tempURL?.path, category: .temp)
    }
    
    private func scanLogFiles() -> [CleanupItem] {
        let logURL = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first?.appendingPathComponent("Logs")
        return scanDirectory(logURL?.path, category: .logs)
    }
    
    private func scanBrowserData() -> [CleanupItem] {
        let homeURL = fileManager.homeDirectoryForCurrentUser
        let browserPaths = [
            homeURL.appendingPathComponent("Library/Application Support/Google/Chrome/Default/Cache").path,
            homeURL.appendingPathComponent("Library/Safari/LocalStorage").path,
            homeURL.appendingPathComponent("Library/Application Support/Firefox/Profiles").path
        ]
        
        var items: [CleanupItem] = []
        for path in browserPaths {
            items.append(contentsOf: scanDirectory(path, category: .browser))
        }
        return items
    }
    
    private func scanDownloads() -> [CleanupItem] {
        let downloadsURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first
        return scanDirectory(downloadsURL?.path, category: .downloads)
    }
    
    private func scanSystemCache() -> [CleanupItem] {
        let systemCachePaths = [
            "/Library/Caches",
            "/System/Library/Caches"
        ]
        
        var items: [CleanupItem] = []
        for path in systemCachePaths {
            items.append(contentsOf: scanDirectory(path, category: .systemCache))
        }
        return items
    }
    
    private func scanApplications() -> [CleanupItem] {
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        return scanDirectory(appSupportURL?.path, category: .applications)
    }
    
    private func scanLargeFiles() -> [CleanupItem] {
        let homeURL = fileManager.homeDirectoryForCurrentUser
        return scanLargeFilesInDirectory(homeURL.path, category: .largeFiles)
    }
    
    private func scanDuplicates() -> [CleanupItem] {
        let homeURL = fileManager.homeDirectoryForCurrentUser
        return scanDuplicateFilesInDirectory(homeURL.path, category: .duplicates)
    }
    
    // MARK: - Helper Methods
    private func scanDirectory(_ path: String?, category: CleanupCategory) -> [CleanupItem] {
        guard let path = path, fileManager.fileExists(atPath: path) else { return [] }
        
        var items: [CleanupItem] = []
        
        if let enumerator = fileManager.enumerator(atPath: path) {
            for case let filePath as String in enumerator {
                let fullPath = (path as NSString).appendingPathComponent(filePath)
                
                if shouldSkipFile(fullPath) { continue }
                
                if let attributes = try? fileManager.attributesOfItem(atPath: fullPath),
                   let fileSize = attributes[.size] as? Int64,
                   let modificationDate = attributes[.modificationDate] as? Date {
                    
                    let item = createCleanupItem(
                        name: (filePath as NSString).lastPathComponent,
                        path: fullPath,
                        size: fileSize,
                        category: category,
                        riskLevel: determineRiskLevel(for: category, path: fullPath),
                        lastModified: modificationDate
                    )
                    items.append(item)
                }
            }
        }
        
        return items
    }
    
    private func scanLargeFilesInDirectory(_ path: String, category: CleanupCategory) -> [CleanupItem] {
        guard fileManager.fileExists(atPath: path) else { return [] }
        
        var items: [CleanupItem] = []
        
        if let enumerator = fileManager.enumerator(atPath: path) {
            for case let filePath as String in enumerator {
                let fullPath = (path as NSString).appendingPathComponent(filePath)
                
                if shouldSkipFile(fullPath) { continue }
                
                if let attributes = try? fileManager.attributesOfItem(atPath: fullPath),
                   let fileSize = attributes[.size] as? Int64,
                   let modificationDate = attributes[.modificationDate] as? Date {
                    
                    if fileSize >= settings.maxFileSize {
                        let item = createCleanupItem(
                            name: (filePath as NSString).lastPathComponent,
                            path: fullPath,
                            size: fileSize,
                            category: category,
                            riskLevel: .medium,
                            lastModified: modificationDate
                        )
                        items.append(item)
                    }
                }
            }
        }
        
        return items
    }
    
    private func scanDuplicateFilesInDirectory(_ path: String, category: CleanupCategory) -> [CleanupItem] {
        // Simplified duplicate detection - in a real app, you'd implement more sophisticated logic
        return []
    }
    
    private func shouldSkipFile(_ path: String) -> Bool {
        let fileName = (path as NSString).lastPathComponent
        
        // Skip hidden files if setting is enabled
        if !settings.scanHiddenFiles && fileName.hasPrefix(".") {
            return true
        }
        
        // Skip system files if setting is enabled
        if settings.excludeSystemFiles && path.contains("/System/") {
            return true
        }
        
        // Skip common system files
        let systemFiles = [".DS_Store", "Thumbs.db", ".Spotlight-V100", ".Trashes"]
        if systemFiles.contains(fileName) {
            return true
        }
        
        return false
    }
    
    private func determineRiskLevel(for category: CleanupCategory, path: String) -> CleanupItem.RiskLevel {
        switch category {
        case .trash, .temp, .userCache:
            return .safe
        case .logs, .browser, .downloads:
            return .medium
        case .systemCache, .applications, .largeFiles, .duplicates:
            return .high
        }
    }
    
    private func createCleanupItem(name: String, path: String, size: Int64, category: CleanupCategory, riskLevel: CleanupItem.RiskLevel, lastModified: Date) -> CleanupItem {
        return CleanupItem(
            name: name,
            path: path,
            size: size,
            category: category,
            lastModified: lastModified,
            riskLevel: riskLevel,
            description: generateDescription(for: category)
        )
    }
    
    private func generateDescription(for category: CleanupCategory) -> String {
        switch category {
        case .trash:
            return "휴지통에서 삭제된 파일들입니다. 안전하게 삭제할 수 있습니다."
        case .userCache:
            return "앱 캐시 데이터입니다. 앱을 다시 실행하면 재생성됩니다."
        case .temp:
            return "임시 파일들입니다. 시스템에서 자동으로 생성됩니다."
        case .logs:
            return "시스템 및 앱 로그 파일들입니다."
        case .browser:
            return "브라우저 캐시 및 기록 데이터입니다."
        case .downloads:
            return "다운로드 폴더의 파일들입니다. 확인 후 삭제하세요."
        case .systemCache:
            return "시스템 캐시 파일들입니다. 신중하게 삭제하세요."
        case .applications:
            return "앱 관련 임시 데이터입니다."
        case .largeFiles:
            return "1GB 이상의 대용량 파일들입니다."
        case .duplicates:
            return "중복된 파일들입니다."
        }
    }
    
    // MARK: - Item Management
    func toggleSelection(for item: CleanupItem) {
        if let index = cleanupItems.firstIndex(where: { $0.id == item.id }) {
            cleanupItems[index].isSelected.toggle()
            updateSizes()
        }
    }
    
    func selectAll(in category: CleanupCategory) {
        for index in cleanupItems.indices {
            if cleanupItems[index].category == category {
                cleanupItems[index].isSelected = true
            }
        }
        updateSizes()
    }
    
    func deselectAll(in category: CleanupCategory) {
        for index in cleanupItems.indices {
            if cleanupItems[index].category == category {
                cleanupItems[index].isSelected = false
            }
        }
        updateSizes()
    }
    
    func selectAllSafe() {
        for index in cleanupItems.indices {
            if cleanupItems[index].riskLevel == .safe {
                cleanupItems[index].isSelected = true
            }
        }
        updateSizes()
    }
    
    private func updateSizes() {
        selectedSize = cleanupItems.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
        totalSize = cleanupItems.reduce(0) { $0 + $1.size }
    }
    
    private func groupItemsByCategory() {
        itemsByCategory = Dictionary(grouping: cleanupItems) { $0.category }
    }
    
    // MARK: - Utility Methods
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
import Foundation
import SwiftUI

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

enum CleanupCategory: String, CaseIterable, Identifiable {
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

class DataScanner: ObservableObject {
    @Published var cleanupItems: [CleanupItem] = []
    @Published var isScanning = false
    @Published var totalSize: Int64 = 0
    @Published var searchText = ""
    @Published var showOnlySafe = false
    
    private let fileManager = FileManager.default
    
    var selectedSize: Int64 {
        cleanupItems.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }
    
    var filteredItems: [CleanupItem] {
        var items = cleanupItems
        
        if !searchText.isEmpty {
            items = items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        if showOnlySafe {
            items = items.filter { $0.riskLevel == .safe }
        }
        
        return items.sorted { $0.size > $1.size }
    }
    
    var itemsByCategory: [CleanupCategory: [CleanupItem]] {
        Dictionary(grouping: cleanupItems, by: { $0.category })
    }
    
    func scanForCleanupItems() {
        isScanning = true
        cleanupItems.removeAll()
        totalSize = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            var items: [CleanupItem] = []
            
            // 시스템 캐시
            items.append(contentsOf: self.scanSystemCache())
            
            // 사용자 캐시
            items.append(contentsOf: self.scanUserCache())
            
            // 로그 파일
            items.append(contentsOf: self.scanLogs())
            
            // 다운로드 폴더
            items.append(contentsOf: self.scanDownloads())
            
            // 휴지통
            items.append(contentsOf: self.scanTrash())
            
            // 애플리케이션 캐시
            items.append(contentsOf: self.scanApplicationCache())
            
            // 브라우저 데이터
            items.append(contentsOf: self.scanBrowserData())
            
            // 임시 파일
            items.append(contentsOf: self.scanTempFiles())
            
            let total = items.reduce(0) { $0 + $1.size }
            
            DispatchQueue.main.async {
                self.cleanupItems = items
                self.totalSize = total
                self.isScanning = false
            }
        }
    }
    
    private func scanSystemCache() -> [CleanupItem] {
        var items: [CleanupItem] = []
        let systemCachePaths = [
            "/System/Library/Caches",
            "/Library/Caches"
        ]
        
        for path in systemCachePaths {
            if let size = directorySize(at: path) {
                if let cleanupItem = createCleanupItem(
                    name: "시스템 캐시 - \(URL(fileURLWithPath: path).lastPathComponent)",
                    path: path,
                    size: size,
                    category: .systemCache,
                    riskLevel: .medium
                ) {
                    items.append(cleanupItem)
                }
            }
        }
        
        return items
    }
    
    private func scanUserCache() -> [CleanupItem] {
        var items: [CleanupItem] = []
        
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let cachePath = homeDir.appendingPathComponent("Library/Caches").path
        
        do {
            let cacheContents = try fileManager.contentsOfDirectory(atPath: cachePath)
            for item in cacheContents {
                let itemPath = "\(cachePath)/\(item)"
                if let size = directorySize(at: itemPath) {
                                            if let cleanupItem = createCleanupItem(
                            name: "사용자 캐시 - \(item)",
                            path: itemPath,
                            size: size,
                            category: .userCache,
                            riskLevel: .safe
                        ) {
                            items.append(cleanupItem)
                        }
                }
            }
        } catch {}
        
        return items
    }
    
    private func scanLogs() -> [CleanupItem] {
        var items: [CleanupItem] = []
        let logPaths = [
            "/var/log",
            NSHomeDirectory() + "/Library/Logs"
        ]
        
        for path in logPaths {
            if let size = directorySize(at: path) {
                if let cleanupItem = createCleanupItem(
                    name: "로그 파일 - \(URL(fileURLWithPath: path).lastPathComponent)",
                    path: path,
                    size: size,
                    category: .logs,
                    riskLevel: .safe
                ) {
                    items.append(cleanupItem)
                }
            }
        }
        
        return items
    }
    
    private func scanDownloads() -> [CleanupItem] {
        var items: [CleanupItem] = []
        
        if let downloadsDir = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            if let size = directorySize(at: downloadsDir.path) {
                if let cleanupItem = createCleanupItem(
                    name: "다운로드 폴더",
                    path: downloadsDir.path,
                    size: size,
                    category: .downloads,
                    riskLevel: .medium
                ) {
                    items.append(cleanupItem)
                }
            }
        }
        
        return items
    }
    
    private func scanTrash() -> [CleanupItem] {
        var items: [CleanupItem] = []
        
        if let trashDir = fileManager.urls(for: .trashDirectory, in: .userDomainMask).first {
            if let size = directorySize(at: trashDir.path) {
                if let cleanupItem = createCleanupItem(
                    name: "휴지통",
                    path: trashDir.path,
                    size: size,
                    category: .trash,
                    riskLevel: .safe
                ) {
                    items.append(cleanupItem)
                }
            }
        }
        
        return items
    }
    
    private func scanApplicationCache() -> [CleanupItem] {
        var items: [CleanupItem] = []
        
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let appSupportPath = homeDir.appendingPathComponent("Library/Application Support").path
        
        do {
            let appContents = try fileManager.contentsOfDirectory(atPath: appSupportPath)
            for app in appContents.prefix(10) { // 상위 10개만
                let appPath = "\(appSupportPath)/\(app)"
                if let size = directorySize(at: appPath), size > 100_000_000 { // 100MB 이상만
                    if let cleanupItem = createCleanupItem(
                        name: "앱 데이터 - \(app)",
                        path: appPath,
                        size: size,
                        category: .applications,
                        riskLevel: .safe
                    ) {
                        items.append(cleanupItem)
                    }
                }
            }
        } catch {}
        
        return items
    }
    
    private func scanBrowserData() -> [CleanupItem] {
        var items: [CleanupItem] = []
        
        let browserPaths = [
            NSHomeDirectory() + "/Library/Safari",
            NSHomeDirectory() + "/Library/Application Support/Google/Chrome",
            NSHomeDirectory() + "/Library/Application Support/Firefox"
        ]
        
        for path in browserPaths {
            if fileManager.fileExists(atPath: path) {
                if let size = directorySize(at: path) {
                    let browserName = URL(fileURLWithPath: path).lastPathComponent
                    if let cleanupItem = createCleanupItem(
                        name: "브라우저 데이터 - \(browserName)",
                        path: path,
                        size: size,
                        category: .browser,
                        riskLevel: .safe
                    ) {
                        items.append(cleanupItem)
                    }
                }
            }
        }
        
        return items
    }
    
    private func scanTempFiles() -> [CleanupItem] {
        var items: [CleanupItem] = []
        let tempPaths = [
            "/tmp",
            "/var/tmp",
            NSTemporaryDirectory()
        ]
        
        for path in tempPaths {
            if let size = directorySize(at: path) {
                if let cleanupItem = createCleanupItem(
                    name: "임시 파일 - \(URL(fileURLWithPath: path).lastPathComponent)",
                    path: path,
                    size: size,
                    category: .temp,
                    riskLevel: .safe
                ) {
                    items.append(cleanupItem)
                }
            }
        }
        
        return items
    }
    
    private func directorySize(at path: String) -> Int64? {
        guard fileManager.fileExists(atPath: path) else { return nil }
        
        do {
            var totalSize: Int64 = 0
            let enumerator = fileManager.enumerator(atPath: path)
            
            while let file = enumerator?.nextObject() as? String {
                let filePath = "\(path)/\(file)"
                let attributes = try fileManager.attributesOfItem(atPath: filePath)
                if let fileSize = attributes[.size] as? Int64 {
                    totalSize += fileSize
                }
            }
            
            return totalSize
        } catch {
            return nil
        }
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    // MARK: - Enhanced Item Management
    
    func toggleSelection(for item: CleanupItem) {
        if let index = cleanupItems.firstIndex(where: { $0.id == item.id }) {
            cleanupItems[index].isSelected.toggle()
        }
    }
    
    func selectAll(in category: CleanupCategory) {
        for index in cleanupItems.indices {
            if cleanupItems[index].category == category {
                cleanupItems[index].isSelected = true
            }
        }
    }
    
    func deselectAll(in category: CleanupCategory) {
        for index in cleanupItems.indices {
            if cleanupItems[index].category == category {
                cleanupItems[index].isSelected = false
            }
        }
    }
    
    func selectAllSafe() {
        for index in cleanupItems.indices {
            if cleanupItems[index].riskLevel == .safe {
                cleanupItems[index].isSelected = true
            }
        }
    }
    
    // MARK: - Enhanced Scanning Methods
    
    private func createCleanupItem(name: String, path: String, size: Int64, category: CleanupCategory, riskLevel: CleanupItem.RiskLevel = .safe) -> CleanupItem? {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: path)
            let modDate = attributes[.modificationDate] as? Date ?? Date()
            
            return CleanupItem(
                name: name,
                path: path,
                size: size,
                category: category,
                lastModified: modDate,
                riskLevel: riskLevel,
                description: generateDescription(for: name, category: category)
            )
        } catch {
            return nil
        }
    }
    
    private func generateDescription(for filename: String, category: CleanupCategory) -> String {
        switch category {
        case .systemCache:
            return "시스템 성능 향상을 위해 정리 가능"
        case .userCache:
            return "앱 캐시 - 삭제 후 자동 재생성됨"
        case .logs:
            return "로그 파일 - 문제 해결용 기록"
        case .downloads:
            return "다운로드된 파일 - 수동 확인 권장"
        case .trash:
            return "휴지통 내용 - 완전 삭제 가능"
        case .applications:
            return "앱 데이터 - 설정이 초기화될 수 있음"
        case .browser:
            return "브라우저 데이터 - 로그인 정보 확인"
        case .temp:
            return "임시 파일 - 안전하게 삭제 가능"
        case .largeFiles:
            return "대용량 파일 - 수동 확인 필요"
        case .duplicates:
            return "중복 파일 - 원본은 유지됨"
        }
    }
}
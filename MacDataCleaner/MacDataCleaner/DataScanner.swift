import Foundation
import SwiftUI

struct CleanupItem: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let size: Int64
    let category: CleanupCategory
    var isSelected: Bool = false
}

enum CleanupCategory: String, CaseIterable {
    case systemCache = "시스템 캐시"
    case userCache = "사용자 캐시"
    case logs = "로그 파일"
    case downloads = "다운로드"
    case trash = "휴지통"
    case applications = "응용프로그램 캐시"
    case browser = "브라우저 데이터"
    case temp = "임시 파일"
    
    var icon: String {
        switch self {
        case .systemCache: return "gear"
        case .userCache: return "person.crop.circle"
        case .logs: return "doc.text"
        case .downloads: return "arrow.down.circle"
        case .trash: return "trash"
        case .applications: return "app"
        case .browser: return "safari"
        case .temp: return "clock"
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
        }
    }
}

class DataScanner: ObservableObject {
    @Published var cleanupItems: [CleanupItem] = []
    @Published var isScanning = false
    @Published var totalSize: Int64 = 0
    
    private let fileManager = FileManager.default
    
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
                items.append(CleanupItem(
                    name: "시스템 캐시 - \(URL(fileURLWithPath: path).lastPathComponent)",
                    path: path,
                    size: size,
                    category: .systemCache
                ))
            }
        }
        
        return items
    }
    
    private func scanUserCache() -> [CleanupItem] {
        var items: [CleanupItem] = []
        
        if let homeDir = fileManager.urls(for: .homeDirectory, in: .userDomainMask).first {
            let cachePath = homeDir.appendingPathComponent("Library/Caches").path
            
            do {
                let cacheContents = try fileManager.contentsOfDirectory(atPath: cachePath)
                for item in cacheContents {
                    let itemPath = "\(cachePath)/\(item)"
                    if let size = directorySize(at: itemPath) {
                        items.append(CleanupItem(
                            name: "사용자 캐시 - \(item)",
                            path: itemPath,
                            size: size,
                            category: .userCache
                        ))
                    }
                }
            } catch {}
        }
        
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
                items.append(CleanupItem(
                    name: "로그 파일 - \(URL(fileURLWithPath: path).lastPathComponent)",
                    path: path,
                    size: size,
                    category: .logs
                ))
            }
        }
        
        return items
    }
    
    private func scanDownloads() -> [CleanupItem] {
        var items: [CleanupItem] = []
        
        if let downloadsDir = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            if let size = directorySize(at: downloadsDir.path) {
                items.append(CleanupItem(
                    name: "다운로드 폴더",
                    path: downloadsDir.path,
                    size: size,
                    category: .downloads
                ))
            }
        }
        
        return items
    }
    
    private func scanTrash() -> [CleanupItem] {
        var items: [CleanupItem] = []
        
        if let trashDir = fileManager.urls(for: .trashDirectory, in: .userDomainMask).first {
            if let size = directorySize(at: trashDir.path) {
                items.append(CleanupItem(
                    name: "휴지통",
                    path: trashDir.path,
                    size: size,
                    category: .trash
                ))
            }
        }
        
        return items
    }
    
    private func scanApplicationCache() -> [CleanupItem] {
        var items: [CleanupItem] = []
        
        if let homeDir = fileManager.urls(for: .homeDirectory, in: .userDomainMask).first {
            let appSupportPath = homeDir.appendingPathComponent("Library/Application Support").path
            
            do {
                let appContents = try fileManager.contentsOfDirectory(atPath: appSupportPath)
                for app in appContents.prefix(10) { // 상위 10개만
                    let appPath = "\(appSupportPath)/\(app)"
                    if let size = directorySize(at: appPath), size > 100_000_000 { // 100MB 이상만
                        items.append(CleanupItem(
                            name: "앱 데이터 - \(app)",
                            path: appPath,
                            size: size,
                            category: .applications
                        ))
                    }
                }
            } catch {}
        }
        
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
                    items.append(CleanupItem(
                        name: "브라우저 데이터 - \(browserName)",
                        path: path,
                        size: size,
                        category: .browser
                    ))
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
                items.append(CleanupItem(
                    name: "임시 파일 - \(URL(fileURLWithPath: path).lastPathComponent)",
                    path: path,
                    size: size,
                    category: .temp
                ))
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
}
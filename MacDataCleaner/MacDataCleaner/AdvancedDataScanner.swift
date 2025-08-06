import Foundation
import SwiftUI
import UniformTypeIdentifiers

class AdvancedDataScanner: ObservableObject {
    @Published var cleanupItems: [CleanupItem] = []
    @Published var isScanning: Bool = false
    @Published var scanProgress = ScanProgress()
    @Published var settings = CleanupSettings()
    
    private let fileManager = FileManager.default
    private var scanTask: Task<Void, Never>?
    
    var totalSize: Int64 {
        cleanupItems.reduce(0) { $0 + $1.size }
    }
    
    var selectedSize: Int64 {
        cleanupItems.filter { $0.isSelected }.reduce(0) { $0 + $1.size }
    }
    
    var itemsByCategory: [CleanupCategory: [CleanupItem]] {
        Dictionary(grouping: cleanupItems, by: { $0.category })
    }
    
    func scanForCleanupItems() {
        scanTask?.cancel()
        cleanupItems.removeAll()
        isScanning = true
        scanProgress = ScanProgress()
        
        scanTask = Task { @MainActor in
            await performComprehensiveScan()
            isScanning = false
            scanProgress.isCompleted = true
        }
    }
    
    @MainActor
    private func performComprehensiveScan() async {
        let scanTasks = [
            scanSystemCache,
            scanUserCache,
            scanLogs,
            scanDownloads,
            scanTrash,
            scanApplicationCache,
            scanBrowserData,
            scanTempFiles,
            scanLargeFiles,
            scanDuplicateFiles,
            scanOldFiles
        ]
        
        let totalTasks = scanTasks.count
        
        for (index, task) in scanTasks.enumerated() {
            if Task.isCancelled { return }
            
            let items = await task()
            cleanupItems.append(contentsOf: items)
            
            scanProgress.progress = Double(index + 1) / Double(totalTasks)
            scanProgress.itemsFound = cleanupItems.count
            scanProgress.totalSize = totalSize
        }
    }
    
    // MARK: - Enhanced Scanning Methods
    
    private func scanSystemCache() async -> [CleanupItem] {
        await scanDirectory("/System/Library/Caches", category: .systemCache, riskLevel: .medium)
    }
    
    private func scanUserCache() async -> [CleanupItem] {
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let cachePath = homeDir.appendingPathComponent("Library/Caches")
        return await scanDirectory(cachePath.path, category: .userCache, riskLevel: .safe)
    }
    
    private func scanLogs() async -> [CleanupItem] {
        var items: [CleanupItem] = []
        let logPaths = [
            "/var/log",
            NSHomeDirectory() + "/Library/Logs",
            "/Library/Logs"
        ]
        
        for path in logPaths {
            items.append(contentsOf: await scanDirectory(path, category: .logs, riskLevel: .safe))
        }
        
        return items
    }
    
    private func scanDownloads() async -> [CleanupItem] {
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let downloadsPath = homeDir.appendingPathComponent("Downloads")
        return await scanDirectory(downloadsPath.path, category: .downloads, riskLevel: .medium)
    }
    
    private func scanTrash() async -> [CleanupItem] {
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let trashPath = homeDir.appendingPathComponent(".Trash")
        return await scanDirectory(trashPath.path, category: .trash, riskLevel: .safe)
    }
    
    private func scanApplicationCache() async -> [CleanupItem] {
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let appSupportPath = homeDir.appendingPathComponent("Library/Application Support")
        return await scanDirectory(appSupportPath.path, category: .applications, riskLevel: .safe)
    }
    
    private func scanBrowserData() async -> [CleanupItem] {
        var items: [CleanupItem] = []
        let homeDir = fileManager.homeDirectoryForCurrentUser
        
        let browserPaths = [
            homeDir.appendingPathComponent("Library/Safari/Databases").path,
            homeDir.appendingPathComponent("Library/Application Support/Google/Chrome").path,
            homeDir.appendingPathComponent("Library/Application Support/Firefox").path,
            homeDir.appendingPathComponent("Library/Caches/com.apple.Safari").path
        ]
        
        for path in browserPaths {
            items.append(contentsOf: await scanDirectory(path, category: .browser, riskLevel: .safe))
        }
        
        return items
    }
    
    private func scanTempFiles() async -> [CleanupItem] {
        var items: [CleanupItem] = []
        let tempPaths = [
            "/tmp",
            "/var/tmp",
            NSTemporaryDirectory()
        ]
        
        for path in tempPaths {
            items.append(contentsOf: await scanDirectory(path, category: .temp, riskLevel: .safe))
        }
        
        return items
    }
    
    private func scanLargeFiles() async -> [CleanupItem] {
        let homeDir = fileManager.homeDirectoryForCurrentUser
        return await scanDirectoryForLargeFiles(homeDir.path, minimumSize: 1024 * 1024 * 1024) // 1GB+
    }
    
    private func scanDuplicateFiles() async -> [CleanupItem] {
        // Simplified duplicate detection - in production, would use file hashing
        let homeDir = fileManager.homeDirectoryForCurrentUser
        return await findDuplicatesByName(in: homeDir.path)
    }
    
    private func scanOldFiles() async -> [CleanupItem] {
        let homeDir = fileManager.homeDirectoryForCurrentUser
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -settings.maxFileAge, to: Date()) ?? Date()
        return await scanDirectoryForOldFiles(homeDir.path, olderThan: cutoffDate)
    }
    
    // MARK: - Helper Methods
    
    private func scanDirectory(_ path: String, category: CleanupCategory, riskLevel: CleanupItem.RiskLevel) async -> [CleanupItem] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var items: [CleanupItem] = []
                
                guard self.fileManager.fileExists(atPath: path) else {
                    continuation.resume(returning: items)
                    return
                }
                
                do {
                    let contents = try self.fileManager.contentsOfDirectory(atPath: path)
                    
                    for item in contents.prefix(50) { // Limit for performance
                        if Task.isCancelled { break }
                        
                        let itemPath = "\(path)/\(item)"
                        
                        if let attributes = try? self.fileManager.attributesOfItem(atPath: itemPath),
                           let size = attributes[.size] as? Int64,
                           let modDate = attributes[.modificationDate] as? Date {
                            
                            let isDirectory = attributes[.type] as? FileAttributeType == .typeDirectory
                            let totalSize = isDirectory ? self.directorySize(at: itemPath) ?? size : size
                            
                            if totalSize > self.settings.minFileSize {
                                let cleanupItem = CleanupItem(
                                    name: item,
                                    path: itemPath,
                                    size: totalSize,
                                    category: category,
                                    lastModified: modDate,
                                    isSystemFile: path.hasPrefix("/System"),
                                    riskLevel: riskLevel,
                                    description: self.generateDescription(for: item, category: category)
                                )
                                items.append(cleanupItem)
                            }
                        }
                    }
                } catch {
                    // Handle permission errors silently
                }
                
                continuation.resume(returning: items)
            }
        }
    }
    
    private func scanDirectoryForLargeFiles(_ path: String, minimumSize: Int64) async -> [CleanupItem] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var items: [CleanupItem] = []
                
                let enumerator = self.fileManager.enumerator(atPath: path)
                while let file = enumerator?.nextObject() as? String {
                    if Task.isCancelled { break }
                    
                    let fullPath = "\(path)/\(file)"
                    
                    if let attributes = try? self.fileManager.attributesOfItem(atPath: fullPath),
                       let size = attributes[.size] as? Int64,
                       let modDate = attributes[.modificationDate] as? Date,
                       size > minimumSize {
                        
                        let cleanupItem = CleanupItem(
                            name: file,
                            path: fullPath,
                            size: size,
                            category: .largeFiles,
                            lastModified: modDate,
                            isSystemFile: fullPath.hasPrefix("/System"),
                            riskLevel: .medium,
                            description: "대용량 파일 (\(size.formatBytes()))"
                        )
                        items.append(cleanupItem)
                    }
                }
                
                continuation.resume(returning: items)
            }
        }
    }
    
    private func findDuplicatesByName(in path: String) async -> [CleanupItem] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var items: [CleanupItem] = []
                var fileNames: [String: [String]] = [:]
                
                let enumerator = self.fileManager.enumerator(atPath: path)
                while let file = enumerator?.nextObject() as? String {
                    if Task.isCancelled { break }
                    
                    let fileName = (file as NSString).lastPathComponent
                    let fullPath = "\(path)/\(file)"
                    
                    if fileNames[fileName] == nil {
                        fileNames[fileName] = []
                    }
                    fileNames[fileName]?.append(fullPath)
                }
                
                for (fileName, paths) in fileNames where paths.count > 1 {
                    for (index, path) in paths.enumerated() where index > 0 {
                        if let attributes = try? self.fileManager.attributesOfItem(atPath: path),
                           let size = attributes[.size] as? Int64,
                           let modDate = attributes[.modificationDate] as? Date {
                            
                            let cleanupItem = CleanupItem(
                                name: fileName,
                                path: path,
                                size: size,
                                category: .duplicates,
                                lastModified: modDate,
                                isSystemFile: path.hasPrefix("/System"),
                                riskLevel: .safe,
                                description: "중복 파일 (원본 외 \(paths.count - 1)개)"
                            )
                            items.append(cleanupItem)
                        }
                    }
                }
                
                continuation.resume(returning: items)
            }
        }
    }
    
    private func scanDirectoryForOldFiles(_ path: String, olderThan cutoffDate: Date) async -> [CleanupItem] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var items: [CleanupItem] = []
                
                let enumerator = self.fileManager.enumerator(atPath: path)
                while let file = enumerator?.nextObject() as? String {
                    if Task.isCancelled { break }
                    
                    let fullPath = "\(path)/\(file)"
                    
                    if let attributes = try? self.fileManager.attributesOfItem(atPath: fullPath),
                       let size = attributes[.size] as? Int64,
                       let modDate = attributes[.modificationDate] as? Date,
                       modDate < cutoffDate {
                        
                        let cleanupItem = CleanupItem(
                            name: file,
                            path: fullPath,
                            size: size,
                            category: .oldFiles,
                            lastModified: modDate,
                            isSystemFile: fullPath.hasPrefix("/System"),
                            riskLevel: .medium,
                            description: "오래된 파일 (\(modDate.timeAgoDisplay()))"
                        )
                        items.append(cleanupItem)
                    }
                }
                
                continuation.resume(returning: items)
            }
        }
    }
    
    private func directorySize(at path: String) -> Int64? {
        guard let enumerator = fileManager.enumerator(atPath: path) else { return nil }
        
        var totalSize: Int64 = 0
        
        while let file = enumerator.nextObject() as? String {
            let fullPath = "\(path)/\(file)"
            
            if let attributes = try? fileManager.attributesOfItem(atPath: fullPath),
               let size = attributes[.size] as? Int64 {
                totalSize += size
            }
        }
        
        return totalSize
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
        case .oldFiles:
            return "오래된 파일 - 백업 확인 권장"
        }
    }
    
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
}
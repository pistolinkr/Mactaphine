import Foundation
import SwiftUI

class AdvancedCleanupManager: ObservableObject {
    @Published var isCleaningUp = false
    @Published var cleanupProgress: Double = 0.0
    @Published var cleanupStatus = ""
    @Published var cleanedSize: Int64 = 0
    @Published var cleanupHistory: [CleanupHistoryItem] = []
    @Published var lastCleanupReport: CleanupReport?
    
    private let fileManager = FileManager.default
    private var cleanupTask: Task<Void, Never>?
    
    struct CleanupHistoryItem: Identifiable, Codable {
        let id = UUID()
        let date: Date
        let itemsCount: Int
        let totalSize: Int64
        let categories: [String]
        let riskLevels: [String]
    }
    
    struct CleanupReport {
        let date: Date
        let itemsProcessed: Int
        let totalSizeCleaned: Int64
        let successfulDeletions: Int
        let failedDeletions: Int
        let categoriesAffected: Set<CleanupCategory>
        let timeElapsed: TimeInterval
        let backupCreated: Bool
        let errors: [CleanupError]
    }
    
    struct CleanupError {
        let item: CleanupItem
        let error: Error
        let timestamp: Date
    }
    
    func cleanup(items: [CleanupItem], createBackup: Bool = true) {
        cleanupTask?.cancel()
        
        isCleaningUp = true
        cleanupProgress = 0.0
        cleanedSize = 0
        cleanupStatus = "정리 준비 중..."
        
        let selectedItems = items.filter { $0.isSelected }
        guard !selectedItems.isEmpty else {
            isCleaningUp = false
            return
        }
        
        cleanupTask = Task { @MainActor in
            await performAdvancedCleanup(items: selectedItems, createBackup: createBackup)
        }
    }
    
    @MainActor
    private func performAdvancedCleanup(items: [CleanupItem], createBackup: Bool) async {
        let startTime = Date()
        var successCount = 0
        var failedCount = 0
        var errors: [CleanupError] = []
        let totalItems = items.count
        
        // Create backup if requested
        var backupPath: String?
        if createBackup {
            cleanupStatus = "백업 생성 중..."
            backupPath = await createBackupForItems(items)
        }
        
        // Sort items by risk level (safe first)
        let sortedItems = items.sorted { $0.riskLevel.rawValue < $1.riskLevel.rawValue }
        
        for (index, item) in sortedItems.enumerated() {
            if Task.isCancelled { break }
            
            cleanupStatus = "\(item.name) 정리 중..."
            cleanupProgress = Double(index) / Double(totalItems)
            
            do {
                try await cleanupItemSafely(item)
                successCount += 1
                cleanedSize += item.size
            } catch {
                failedCount += 1
                errors.append(CleanupError(item: item, error: error, timestamp: Date()))
                print("Failed to cleanup \(item.name): \(error)")
            }
            
            // Small delay for UI feedback
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        let endTime = Date()
        let timeElapsed = endTime.timeIntervalSince(startTime)
        
        // Create cleanup report
        let report = CleanupReport(
            date: startTime,
            itemsProcessed: totalItems,
            totalSizeCleaned: cleanedSize,
            successfulDeletions: successCount,
            failedDeletions: failedCount,
            categoriesAffected: Set(items.map { $0.category }),
            timeElapsed: timeElapsed,
            backupCreated: backupPath != nil,
            errors: errors
        )
        
        lastCleanupReport = report
        
        // Add to history
        let historyItem = CleanupHistoryItem(
            date: startTime,
            itemsCount: totalItems,
            totalSize: cleanedSize,
            categories: Array(Set(items.map { $0.category.rawValue })),
            riskLevels: Array(Set(items.map { $0.riskLevel.rawValue }))
        )
        cleanupHistory.insert(historyItem, at: 0)
        
        // Keep only last 50 history items
        if cleanupHistory.count > 50 {
            cleanupHistory = Array(cleanupHistory.prefix(50))
        }
        
        cleanupProgress = 1.0
        cleanupStatus = "정리 완료! \(successCount)개 성공, \(failedCount)개 실패"
        isCleaningUp = false
        
        // Auto-hide status after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if !self.isCleaningUp {
                self.cleanupStatus = ""
            }
        }
        
        // Save history to disk
        saveCleanupHistory()
    }
    
    private func cleanupItemSafely(_ item: CleanupItem) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    // Check if item still exists
                    guard self.fileManager.fileExists(atPath: item.path) else {
                        continuation.resume()
                        return
                    }
                    
                    // Additional safety checks for high-risk items
                    if item.riskLevel == .high {
                        // More conservative approach for high-risk items
                        if item.isSystemFile || item.path.hasPrefix("/System") {
                            throw CleanupManagerError.highRiskSystemFile
                        }
                    }
                    
                    // Perform the actual deletion
                    if item.category == .trash {
                        // Empty trash properly
                        try self.emptyTrashItem(at: item.path)
                    } else {
                        // Regular file deletion
                        try self.fileManager.removeItem(atPath: item.path)
                    }
                    
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func createBackupForItems(_ items: [CleanupItem]) async -> String? {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                do {
                    let backupDir = NSHomeDirectory() + "/Desktop/MacDataCleaner_Backup_\(Date().timeIntervalSince1970)"
                    try self.fileManager.createDirectory(atPath: backupDir, withIntermediateDirectories: true)
                    
                    for item in items.prefix(10) { // Limit backup size
                        if item.riskLevel != .safe && item.size < 100_000_000 { // < 100MB
                            let backupPath = "\(backupDir)/\(item.name)"
                            try? self.fileManager.copyItem(atPath: item.path, toPath: backupPath)
                        }
                    }
                    
                    continuation.resume(returning: backupDir)
                } catch {
                    print("Backup creation failed: \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    private func emptyTrashItem(at path: String) throws {
        // Use NSWorkspace for proper trash handling
        let url = URL(fileURLWithPath: path)
        try fileManager.trashItem(at: url, resultingItemURL: nil)
    }
    
    private func saveCleanupHistory() {
        do {
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            let historyURL = documentsPath?.appendingPathComponent("cleanup_history.json")
            
            if let url = historyURL {
                let data = try JSONEncoder().encode(cleanupHistory)
                try data.write(to: url)
            }
        } catch {
            print("Failed to save cleanup history: \(error)")
        }
    }
    
    func loadCleanupHistory() {
        do {
            let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
            let historyURL = documentsPath?.appendingPathComponent("cleanup_history.json")
            
            if let url = historyURL, fileManager.fileExists(atPath: url.path) {
                let data = try Data(contentsOf: url)
                cleanupHistory = try JSONDecoder().decode([CleanupHistoryItem].self, from: data)
            }
        } catch {
            print("Failed to load cleanup history: \(error)")
        }
    }
    
    func cancelCleanup() {
        cleanupTask?.cancel()
        isCleaningUp = false
        cleanupStatus = "정리가 취소되었습니다"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.cleanupStatus = ""
        }
    }
    
    func getEstimatedTime(for items: [CleanupItem]) -> TimeInterval {
        let selectedItems = items.filter { $0.isSelected }
        // Rough estimation: 0.1 seconds per item + 0.01 seconds per MB
        let baseTime = Double(selectedItems.count) * 0.1
        let sizeTime = Double(selectedItems.reduce(0) { $0 + $1.size }) / (1024 * 1024) * 0.01
        return baseTime + sizeTime
    }
    
    func getTotalSavedSpace() -> Int64 {
        cleanupHistory.reduce(0) { $0 + $1.totalSize }
    }
    
    func getCleanupFrequency() -> String {
        guard cleanupHistory.count >= 2 else { return "정보 없음" }
        
        let timeSpan = cleanupHistory.first!.date.timeIntervalSince(cleanupHistory.last!.date)
        let averageInterval = timeSpan / Double(cleanupHistory.count - 1)
        
        let days = averageInterval / (24 * 60 * 60)
        
        if days < 1 {
            return "매일"
        } else if days < 7 {
            return "\(Int(days))일마다"
        } else if days < 30 {
            return "\(Int(days / 7))주마다"
        } else {
            return "\(Int(days / 30))달마다"
        }
    }
}

enum CleanupManagerError: Error {
    case highRiskSystemFile
    case insufficientPermissions
    case fileInUse
    case unknownError
    
    var localizedDescription: String {
        switch self {
        case .highRiskSystemFile:
            return "고위험 시스템 파일은 삭제할 수 없습니다"
        case .insufficientPermissions:
            return "파일을 삭제할 권한이 없습니다"
        case .fileInUse:
            return "파일이 사용 중입니다"
        case .unknownError:
            return "알 수 없는 오류가 발생했습니다"
        }
    }
}
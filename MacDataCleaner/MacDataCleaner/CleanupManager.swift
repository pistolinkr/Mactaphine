import Foundation
import SwiftUI

class CleanupManager: ObservableObject {
    @Published var isCleaningUp = false
    @Published var cleanupProgress: Double = 0.0
    @Published var cleanupStatus = ""
    @Published var cleanedSize: Int64 = 0
    
    private let fileManager = FileManager.default
    
    func cleanup(items: [CleanupItem]) {
        isCleaningUp = true
        cleanupProgress = 0.0
        cleanedSize = 0
        
        let selectedItems = items.filter { $0.isSelected }
        guard !selectedItems.isEmpty else {
            isCleaningUp = false
            return
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            let totalItems = selectedItems.count
            
            for (index, item) in selectedItems.enumerated() {
                DispatchQueue.main.async {
                    self.cleanupStatus = "\(item.name) 정리 중..."
                    self.cleanupProgress = Double(index) / Double(totalItems)
                }
                
                self.cleanupItem(item)
                
                DispatchQueue.main.async {
                    self.cleanedSize += item.size
                }
                
                Thread.sleep(forTimeInterval: 0.5) // 시각적 효과를 위한 지연
            }
            
            DispatchQueue.main.async {
                self.cleanupProgress = 1.0
                self.cleanupStatus = "정리 완료!"
                self.isCleaningUp = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.cleanupStatus = ""
                    self.cleanedSize = 0
                }
            }
        }
    }
    
    private func cleanupItem(_ item: CleanupItem) {
        switch item.category {
        case .trash:
            emptyTrash()
        case .userCache, .systemCache, .applications:
            cleanDirectory(at: item.path, preserveStructure: true)
        case .logs:
            cleanLogs(at: item.path)
        case .downloads:
            // 다운로드는 사용자 확인 후에만 삭제
            break
        case .browser:
            cleanBrowserData(at: item.path)
        case .temp:
            cleanDirectory(at: item.path, preserveStructure: false)
        case .largeFiles:
            // 대용량 파일은 개별 삭제
            deleteFile(at: item.path)
        case .duplicates:
            // 중복 파일 삭제
            deleteFile(at: item.path)
        }
    }
    
    private func emptyTrash() {
        do {
            if let trashDir = fileManager.urls(for: .trashDirectory, in: .userDomainMask).first {
                let contents = try fileManager.contentsOfDirectory(at: trashDir, includingPropertiesForKeys: nil)
                for item in contents {
                    try fileManager.removeItem(at: item)
                }
            }
        } catch {
            print("휴지통 비우기 실패: \(error)")
        }
    }
    
    private func cleanDirectory(at path: String, preserveStructure: Bool) {
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            for item in contents {
                let itemPath = "\(path)/\(item)"
                
                if preserveStructure {
                    // 디렉토리 구조는 유지하고 내용만 삭제
                    var isDirectory: ObjCBool = false
                    if fileManager.fileExists(atPath: itemPath, isDirectory: &isDirectory) {
                        if isDirectory.boolValue {
                            cleanDirectory(at: itemPath, preserveStructure: false)
                        } else {
                            try fileManager.removeItem(atPath: itemPath)
                        }
                    }
                } else {
                    try fileManager.removeItem(atPath: itemPath)
                }
            }
        } catch {
            print("디렉토리 정리 실패: \(error)")
        }
    }
    
    private func cleanLogs(at path: String) {
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: path)
            for item in contents {
                let itemPath = "\(path)/\(item)"
                let attributes = try fileManager.attributesOfItem(atPath: itemPath)
                
                // 7일 이상 된 로그 파일만 삭제
                if let modificationDate = attributes[.modificationDate] as? Date {
                    let daysSinceModification = Date().timeIntervalSince(modificationDate) / (24 * 60 * 60)
                    if daysSinceModification > 7 {
                        try fileManager.removeItem(atPath: itemPath)
                    }
                }
            }
        } catch {
            print("로그 정리 실패: \(error)")
        }
    }
    
    private func cleanBrowserData(at path: String) {
        // 브라우저 캐시만 정리 (북마크, 비밀번호 등은 보존)
        let cachePaths = [
            "\(path)/Cache",
            "\(path)/Caches",
            "\(path)/Default/Cache",
            "\(path)/Default/Caches"
        ]
        
        for cachePath in cachePaths {
            if fileManager.fileExists(atPath: cachePath) {
                cleanDirectory(at: cachePath, preserveStructure: false)
            }
        }
    }
    
    private func deleteFile(at path: String) {
        do {
            try fileManager.removeItem(atPath: path)
        } catch {
            print("Failed to delete file at \(path): \(error)")
        }
    }
    
    func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
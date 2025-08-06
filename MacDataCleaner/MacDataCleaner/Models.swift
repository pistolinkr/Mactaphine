import Foundation
import SwiftUI

// MARK: - Enhanced Data Models

struct CleanupItem: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    let size: Int64
    let category: CleanupCategory
    let lastModified: Date
    let isSystemFile: Bool
    let riskLevel: RiskLevel
    var isSelected: Bool = false
    var description: String = ""
    
    enum RiskLevel: String, CaseIterable, Codable {
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
    case oldFiles = "오래된 파일"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .systemCache: return "gearshape.2"
        case .userCache: return "person.crop.circle"
        case .logs: return "doc.text.below.ecg"
        case .downloads: return "arrow.down.circle.fill"
        case .trash: return "trash.fill"
        case .applications: return "app.badge"
        case .browser: return "globe"
        case .temp: return "clock.arrow.circlepath"
        case .largeFiles: return "doc.badge.plus"
        case .duplicates: return "doc.on.doc"
        case .oldFiles: return "calendar.badge.clock"
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
        case .oldFiles: return .brown
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
        case .oldFiles: return "1년 이상 미사용 파일"
        }
    }
}

// MARK: - Settings and Preferences

struct CleanupSettings: Codable {
    var autoScan: Bool = true
    var scanOnStartup: Bool = false
    var showHiddenFiles: Bool = false
    var confirmBeforeDelete: Bool = true
    var createBackup: Bool = true
    var maxFileAge: Int = 365 // days
    var minFileSize: Int64 = 1024 * 1024 // 1MB
    var excludedPaths: [String] = []
    var customRules: [CustomRule] = []
    
    struct CustomRule: Codable, Identifiable {
        let id = UUID()
        var name: String
        var pattern: String
        var isEnabled: Bool = true
        var riskLevel: CleanupItem.RiskLevel = .medium
    }
}

// MARK: - Scan Progress

struct ScanProgress {
    var currentPath: String = ""
    var itemsFound: Int = 0
    var totalSize: Int64 = 0
    var progress: Double = 0.0
    var isCompleted: Bool = false
}

// MARK: - Extensions

extension Int64 {
    func formatBytes() -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: self)
    }
}

extension Date {
    func timeAgoDisplay() -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
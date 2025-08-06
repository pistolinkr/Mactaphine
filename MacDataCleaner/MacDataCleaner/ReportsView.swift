import SwiftUI

struct ReportsView: View {
    @ObservedObject var cleanupManager: AdvancedCleanupManager
    @State private var selectedTimeRange = TimeRange.month
    @Environment(\.dismiss) private var dismiss
    
    enum TimeRange: String, CaseIterable {
        case week = "1주"
        case month = "1달"
        case quarter = "3달"
        case year = "1년"
        case all = "전체"
    }
    
    private var filteredHistory: [AdvancedCleanupManager.CleanupHistoryItem] {
        let now = Date()
        let cutoffDate: Date
        
        switch selectedTimeRange {
        case .week:
            cutoffDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .month:
            cutoffDate = Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
        case .quarter:
            cutoffDate = Calendar.current.date(byAdding: .month, value: -3, to: now) ?? now
        case .year:
            cutoffDate = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
        case .all:
            cutoffDate = Date.distantPast
        }
        
        return cleanupManager.cleanupHistory.filter { $0.date >= cutoffDate }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("정리 보고서")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("시스템 정리 활동 분석")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Picker("기간", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 300)
                    
                    Button("완료") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                
                Divider()
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        // Summary Cards
                        summaryCardsView
                        
                        // Charts
                        if !filteredHistory.isEmpty {
                            cleanupTrendChart
                            categoryBreakdownChart
                            riskLevelAnalysis
                        }
                        
                        // Recent Activity
                        recentActivityView
                        
                        // Performance Insights
                        performanceInsightsView
                    }
                    .padding()
                }
            }
        }
        .frame(width: 900, height: 700)
    }
    
    private var summaryCardsView: some View {
        HStack(spacing: 16) {
            SummaryCard(
                title: "총 정리량",
                value: filteredHistory.reduce(0) { $0 + $1.totalSize }.formatBytes(),
                icon: "trash.fill",
                color: .red
            )
            
            SummaryCard(
                title: "정리 횟수",
                value: "\(filteredHistory.count)회",
                icon: "repeat.circle.fill",
                color: .blue
            )
            
            SummaryCard(
                title: "평균 정리량",
                value: filteredHistory.isEmpty ? "0 KB" : (filteredHistory.reduce(0) { $0 + $1.totalSize } / Int64(filteredHistory.count)).formatBytes(),
                icon: "chart.bar.fill",
                color: .green
            )
            
            SummaryCard(
                title: "절약된 공간",
                value: cleanupManager.getTotalSavedSpace().formatBytes(),
                icon: "internaldrive.fill",
                color: .purple
            )
        }
    }
    
    private var cleanupTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("정리 동향")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(Array(filteredHistory.prefix(10).enumerated()), id: \.offset) { index, item in
                    HStack {
                        Text(item.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .frame(width: 80, alignment: .leading)
                        
                        Rectangle()
                            .fill(Color.blue)
                            .frame(width: max(20, CGFloat(item.totalSize / 1024 / 1024) / 10), height: 16)
                            .cornerRadius(4)
                        
                        Text(item.totalSize.formatBytes())
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var categoryBreakdownChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("카테고리별 분석")
                .font(.headline)
                .fontWeight(.semibold)
            
            let categoryData = Dictionary(grouping: filteredHistory.flatMap { $0.categories }) { $0 }
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }
            
            VStack(spacing: 8) {
                ForEach(Array(categoryData.prefix(5)), id: \.key) { category, count in
                    HStack {
                        Text(category)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        HStack {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: CGFloat(count * 20), height: 20)
                                .cornerRadius(4)
                            
                            Text("\(count)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
            }
            .frame(height: 250)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var riskLevelAnalysis: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("위험도별 분석")
                .font(.headline)
                .fontWeight(.semibold)
            
            let riskData = Dictionary(grouping: filteredHistory.flatMap { $0.riskLevels }) { $0 }
                .mapValues { $0.count }
                .sorted { $0.value > $1.value }
            
            VStack(spacing: 8) {
                ForEach(Array(riskData), id: \.key) { risk, count in
                    HStack {
                        Circle()
                            .fill(risk == "안전" ? Color.green : risk == "주의" ? Color.orange : Color.red)
                            .frame(width: 12, height: 12)
                        
                        Text(risk)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(count)회")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
            .frame(height: 200)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var recentActivityView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("최근 활동")
                .font(.headline)
                .fontWeight(.semibold)
            
            if filteredHistory.isEmpty {
                Text("선택한 기간에 정리 활동이 없습니다")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(filteredHistory.prefix(5)) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("\(item.itemsCount)개 항목 • \(item.totalSize.formatBytes())")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            ForEach(item.categories.prefix(3), id: \.self) { category in
                                Text(category)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.accentColor.opacity(0.1))
                                    .cornerRadius(4)
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private var performanceInsightsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("성능 인사이트")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                InsightRow(
                    icon: "clock.fill",
                    title: "정리 빈도",
                    value: cleanupManager.getCleanupFrequency(),
                    color: .blue
                )
                
                InsightRow(
                    icon: "speedometer",
                    title: "평균 정리 시간",
                    value: getAverageCleanupTime(),
                    color: .green
                )
                
                InsightRow(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "정리 효율",
                    value: getCleanupEfficiency(),
                    color: .purple
                )
                
                InsightRow(
                    icon: "shield.checkered",
                    title: "안전성 점수",
                    value: getSafetyScore(),
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
    
    private func getAverageCleanupTime() -> String {
        // Estimate based on items count (would be better with actual timing data)
        let avgItems = filteredHistory.isEmpty ? 0 : filteredHistory.reduce(0) { $0 + $1.itemsCount } / filteredHistory.count
        let estimatedSeconds = Double(avgItems) * 0.1
        
        if estimatedSeconds < 60 {
            return "\(Int(estimatedSeconds))초"
        } else {
            return "\(Int(estimatedSeconds / 60))분 \(Int(estimatedSeconds.truncatingRemainder(dividingBy: 60)))초"
        }
    }
    
    private func getCleanupEfficiency() -> String {
        guard !filteredHistory.isEmpty else { return "N/A" }
        
        let totalSize = filteredHistory.reduce(0) { $0 + $1.totalSize }
        let totalItems = filteredHistory.reduce(0) { $0 + $1.itemsCount }
        
        if totalItems > 0 {
            let avgSizePerItem = totalSize / Int64(totalItems)
            return avgSizePerItem.formatBytes() + "/항목"
        }
        
        return "N/A"
    }
    
    private func getSafetyScore() -> String {
        guard !filteredHistory.isEmpty else { return "N/A" }
        
        let safeItems = filteredHistory.flatMap { $0.riskLevels }.filter { $0 == "안전" }.count
        let totalRiskItems = filteredHistory.flatMap { $0.riskLevels }.count
        
        if totalRiskItems > 0 {
            let percentage = (safeItems * 100) / totalRiskItems
            return "\(percentage)% 안전"
        }
        
        return "N/A"
    }
}

struct SummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

struct InsightRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.subheadline)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}
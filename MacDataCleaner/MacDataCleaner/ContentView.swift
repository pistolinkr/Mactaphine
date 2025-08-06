import SwiftUI
import Foundation

struct ContentView: View {
    @StateObject private var dataScanner = DataScanner()
    @StateObject private var cleanupManager = CleanupManager()
    @State private var selectedCategory: CleanupCategory? = nil
    @State private var showingCleanupConfirmation = false
    @State private var showingSettings = false
    @State private var showingDetailView = false
    @State private var showingReports = false
    @State private var selectedItem: CleanupItem?
    @State private var searchText = ""
    @State private var sortOption = SortOption.size
    @State private var showOnlySafe = false
    
    enum SortOption: String, CaseIterable {
        case size = "크기"
        case name = "이름"
        case date = "날짜"
        case category = "카테고리"
    }
    
    var filteredItems: [CleanupItem] {
        var items = dataScanner.cleanupItems
        
        // Apply search filter
        if !searchText.isEmpty {
            items = items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Apply category filter
        if let category = selectedCategory {
            items = items.filter { $0.category == category }
        }
        
        // Apply safety filter
        if showOnlySafe {
            items = items.filter { $0.riskLevel == .safe }
        }
        
        // Apply sorting
        switch sortOption {
        case .size:
            items.sort { $0.size > $1.size }
        case .name:
            items.sort { $0.name < $1.name }
        case .date:
            items.sort { $0.lastModified > $1.lastModified }
        case .category:
            items.sort { $0.category.rawValue < $1.category.rawValue }
        }
        
        return items
    }
    
    var selectedItems: [CleanupItem] {
        filteredItems.filter { $0.isSelected }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
            
            // Main Content
            HStack(spacing: 0) {
                // Sidebar
                sidebarView
                
                Divider()
                
                // Main View
                mainContentView
            }
            
            Divider()
            
            // Bottom Action Bar
            bottomActionView
        }
        .frame(minWidth: 1000, minHeight: 700)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            if dataScanner.settings.autoScanOnLaunch {
                dataScanner.scanForCleanupItems()
            }
        }
        .sheet(isPresented: $showingCleanupConfirmation) {
            cleanupConfirmationSheet
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(dataScanner: dataScanner)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .font(.title)
                        .foregroundStyle(.linearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Mactaphine")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if !dataScanner.isScanning && !dataScanner.cleanupItems.isEmpty {
                            Text("\(dataScanner.cleanupItems.count)개 항목 • \(dataScanner.formatBytes(dataScanner.totalSize))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Settings Button
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.2")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("설정")
                    
                    if dataScanner.isScanning {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("스캔 중...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button("새로고침") {
                            dataScanner.scanForCleanupItems()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
            }
            
            // Search and filter row
            if !dataScanner.cleanupItems.isEmpty {
                HStack(spacing: 12) {
                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("파일 검색...", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .frame(maxWidth: 300)
                    
                    Toggle("안전한 항목만", isOn: $showOnlySafe)
                        .toggleStyle(.checkbox)
                    
                    Spacer()
                    
                    // Quick action buttons
                    HStack(spacing: 8) {
                        Button("안전한 항목 선택") {
                            dataScanner.selectAllSafe()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("모두 해제") {
                            for category in CleanupCategory.allCases {
                                dataScanner.deselectAll(in: category)
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
    
    // MARK: - Sidebar View
    private var sidebarView: some View {
        VStack(spacing: 0) {
            // Category List
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(CleanupCategory.allCases) { category in
                        CategoryRowView(
                            category: category,
                            isSelected: selectedCategory == category,
                            itemCount: dataScanner.itemsByCategory[category]?.count ?? 0,
                            totalSize: dataScanner.itemsByCategory[category]?.reduce(0) { $0 + $1.size } ?? 0,
                            formatBytes: dataScanner.formatBytes
                        ) {
                            selectedCategory = selectedCategory == category ? nil : category
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(width: 250)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        VStack(spacing: 0) {
            if dataScanner.isScanning {
                scanningView
            } else if dataScanner.cleanupItems.isEmpty {
                emptyStateView
            } else {
                itemListView
            }
        }
    }
    
    private var scanningView: some View {
        VStack(spacing: 20) {
            ProgressView(value: dataScanner.scanProgress)
                .progressViewStyle(.linear)
                .frame(width: 300)
            
            Text("시스템을 스캔하고 있습니다...")
                .font(.headline)
            
            Text("\(Int(dataScanner.scanProgress * 100))% 완료")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)
            
            Text("정리할 항목이 없습니다")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("시스템이 깨끗한 상태입니다!")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button("다시 스캔") {
                dataScanner.scanForCleanupItems()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var itemListView: some View {
        VStack(spacing: 0) {
            // List Header
            HStack {
                Text("\(filteredItems.count)개 항목")
                    .font(.headline)
                
                Spacer()
                
                Picker("정렬", selection: $sortOption) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Items List
            ScrollView {
                LazyVStack(spacing: 2) {
                    ForEach(filteredItems) { item in
                        ItemRowView(
                            item: item,
                            onToggle: {
                                dataScanner.toggleSelection(for: item)
                            }
                        )
                        .onTapGesture {
                            selectedItem = item
                            showingDetailView = true
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    // MARK: - Bottom Action View
    private var bottomActionView: some View {
        HStack(spacing: 16) {
            // Selection info
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
                
                Text("\(selectedItems.count)개 선택됨")
                    .font(.headline)
                
                Text("• \(dataScanner.formatBytes(dataScanner.selectedSize))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                Button("선택 해제") {
                    for item in selectedItems {
                        dataScanner.toggleSelection(for: item)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(selectedItems.isEmpty)
                
                Button("선택 항목 정리") {
                    showingCleanupConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedItems.isEmpty)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Cleanup Confirmation Sheet
    private var cleanupConfirmationSheet: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("정리 확인")
                .font(.title)
                .fontWeight(.bold)
            
            Text("선택한 \(selectedItems.count)개 항목을 정리하시겠습니까?")
                .font(.body)
                .multilineTextAlignment(.center)
            
            Text("총 \(dataScanner.formatBytes(dataScanner.selectedSize))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 16) {
                Button("취소") {
                    showingCleanupConfirmation = false
                }
                .buttonStyle(.bordered)
                
                Button("정리") {
                    cleanupManager.cleanup(items: selectedItems)
                    showingCleanupConfirmation = false
                    dataScanner.scanForCleanupItems()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
        .frame(width: 400)
    }
}

// MARK: - Category Row View
struct CategoryRowView: View {
    let category: CleanupCategory
    let isSelected: Bool
    let itemCount: Int
    let totalSize: Int64
    let formatBytes: (Int64) -> String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(category.rawValue)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    if itemCount > 0 {
                        Text("\(itemCount)개 • \(formatBytes(totalSize))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Item Row View
struct ItemRowView: View {
    let item: CleanupItem
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                Image(systemName: item.isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(item.isSelected ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            
            // Risk Level Icon
            Image(systemName: item.riskLevel.icon)
                .foregroundColor(item.riskLevel.color)
                .frame(width: 20)
            
            // File Icon
            Image(systemName: "doc")
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            // File Info
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                    .lineLimit(1)
                
                Text(item.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Size and Date
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatBytes(item.size))
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(formatDate(item.lastModified))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.clear)
        .cornerRadius(8)
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var dataScanner: DataScanner
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                // Language Settings
                Section("언어 설정") {
                    Picker("언어", selection: $dataScanner.settings.language) {
                        ForEach(Language.allCases, id: \.self) { language in
                            HStack {
                                Text(language.flag)
                                Text(language.displayName)
                            }
                            .tag(language)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: dataScanner.settings.language) {
                        dataScanner.saveSettings()
                    }
                }
                
                // Scan Settings
                Section("스캔 설정") {
                    Toggle("앱 시작 시 자동 스캔", isOn: $dataScanner.settings.autoScanOnLaunch)
                        .onChange(of: dataScanner.settings.autoScanOnLaunch) {
                            dataScanner.saveSettings()
                        }
                    
                    Toggle("숨김 파일 스캔", isOn: $dataScanner.settings.scanHiddenFiles)
                        .onChange(of: dataScanner.settings.scanHiddenFiles) {
                            dataScanner.saveSettings()
                        }
                    
                    Toggle("시스템 파일 제외", isOn: $dataScanner.settings.excludeSystemFiles)
                        .onChange(of: dataScanner.settings.excludeSystemFiles) {
                            dataScanner.saveSettings()
                        }
                    
                    HStack {
                        Text("대용량 파일 기준")
                        Spacer()
                        TextField("크기 (MB)", value: Binding(
                            get: { Int(dataScanner.settings.maxFileSize / 1_000_000) },
                            set: { dataScanner.settings.maxFileSize = Int64($0) * 1_000_000 }
                        ), format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .onChange(of: dataScanner.settings.maxFileSize) {
                            dataScanner.saveSettings()
                        }
                    }
                }
                
                // Scan Categories
                Section("스캔 카테고리") {
                    ForEach(CleanupCategory.allCases, id: \.self) { category in
                        Toggle(category.rawValue, isOn: Binding(
                            get: { dataScanner.settings.scanCategories.contains(category) },
                            set: { isOn in
                                if isOn {
                                    dataScanner.settings.scanCategories.insert(category)
                                } else {
                                    dataScanner.settings.scanCategories.remove(category)
                                }
                                dataScanner.saveSettings()
                            }
                        ))
                    }
                }
                
                // Theme Settings
                Section("테마 설정") {
                    Picker("테마", selection: $dataScanner.settings.theme) {
                        ForEach(AppTheme.allCases, id: \.self) { theme in
                            HStack {
                                Image(systemName: theme.icon)
                                Text(theme.displayName)
                            }
                            .tag(theme)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: dataScanner.settings.theme) {
                        dataScanner.saveSettings()
                    }
                }
                
                // Confirmation Settings
                Section("확인 설정") {
                    Toggle("정리 전 확인 대화상자", isOn: $dataScanner.settings.showConfirmationDialog)
                        .onChange(of: dataScanner.settings.showConfirmationDialog) {
                            dataScanner.saveSettings()
                        }
                }
                
                // Reset Settings
                Section {
                    Button("설정 초기화") {
                        dataScanner.resetSettings()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("설정")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("완료") {
                        dismiss()
                    }
                }
            }
        }
        .frame(width: 500, height: 600)
    }
}

#Preview {
    ContentView()
}
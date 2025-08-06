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
            dataScanner.scanForCleanupItems()
        }
        .sheet(isPresented: $showingCleanupConfirmation) {
            cleanupConfirmationSheet
        }
    }
    
    private var enhancedBottomActionView: some View {
        HStack(spacing: 16) {
            // Selection info
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
                
                if selectedItems.isEmpty {
                    Text("선택된 항목 없음")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(selectedItems.count)개 항목 선택됨")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(dataScanner.formatBytes(dataScanner.selectedSize))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Quick stats
            if !dataScanner.isScanning && !dataScanner.cleanupItems.isEmpty {
                HStack(spacing: 16) {
                    VStack(alignment: .center, spacing: 2) {
                        Text("\(dataScanner.cleanupItems.count)")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("총 항목")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    VStack(alignment: .center, spacing: 2) {
                        Text(dataScanner.formatBytes(dataScanner.totalSize))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("절약 가능")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 12) {
                if !selectedItems.isEmpty {
                    Button("선택 해제") {
                        for category in CleanupCategory.allCases {
                            dataScanner.deselectAll(in: category)
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Button("정리 시작") {
                        showingCleanupConfirmation = true
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundColor(.white)
                    .tint(.red)
                    .disabled(selectedItems.isEmpty)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.7))
    }
    
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
                        
                        TextField("파일 검색...", text: $dataScanner.searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .frame(maxWidth: 300)
                    
                    Toggle("안전한 항목만", isOn: $dataScanner.showOnlySafe)
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
    
    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("카테고리")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)
            
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(CleanupCategory.allCases, id: \.self) { category in
                        let categoryItems = dataScanner.cleanupItems.filter { $0.category == category }
                        let categorySize = categoryItems.reduce(0) { $0 + $1.size }
                        
                        if !categoryItems.isEmpty {
                            CategoryRowView(
                                category: category,
                                itemCount: categoryItems.count,
                                totalSize: categorySize,
                                isSelected: selectedCategory == category,
                                dataScanner: dataScanner
                            ) {
                                selectedCategory = selectedCategory == category ? nil : category
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
            }
            
            Spacer()
        }
        .frame(width: 250)
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            if dataScanner.isScanning {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("시스템 데이터를 스캔하고 있습니다...")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if dataScanner.cleanupItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("정리할 데이터가 없습니다")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("시스템이 깨끗한 상태입니다!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                let itemsToShow = selectedCategory != nil 
                    ? dataScanner.cleanupItems.filter { $0.category == selectedCategory }
                    : dataScanner.cleanupItems
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(itemsToShow.indices, id: \.self) { index in
                            CleanupItemRowView(
                                item: itemsToShow[index],
                                dataScanner: dataScanner
                            )
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    private var bottomActionView: some View {
        HStack {
            if cleanupManager.isCleaningUp {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        ProgressView(value: cleanupManager.cleanupProgress)
                            .frame(width: 200)
                        
                        Text("\(Int(cleanupManager.cleanupProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(cleanupManager.cleanupStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("선택된 항목: \(selectedItems.count)개")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if dataScanner.selectedSize > 0 {
                        Text("정리 예정 크기: \(dataScanner.formatBytes(dataScanner.selectedSize))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if !cleanupManager.isCleaningUp {
                Button("모두 선택") {
                    selectAllItems(true)
                }
                .disabled(dataScanner.cleanupItems.isEmpty)
                
                Button("모두 해제") {
                    selectAllItems(false)
                }
                .disabled(dataScanner.cleanupItems.isEmpty)
                
                Button("정리 시작") {
                    showingCleanupConfirmation = true
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedItems.isEmpty)
            }
        }
        .padding()
    }
    
    private var cleanupConfirmationSheet: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("정리 확인")
                .font(.title)
                .fontWeight(.semibold)
            
            Text("선택된 \(selectedItems.count)개 항목을 정리하시겠습니까?")
                .font(.subheadline)
            
            Text("총 \(dataScanner.formatBytes(dataScanner.selectedSize))의 데이터가 삭제됩니다.")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.red)
            
            Text("이 작업은 되돌릴 수 없습니다.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                Button("취소") {
                    showingCleanupConfirmation = false
                }
                .buttonStyle(.bordered)
                
                Button("정리 시작") {
                    showingCleanupConfirmation = false
                    cleanupManager.cleanup(items: dataScanner.cleanupItems)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(30)
        .frame(width: 400)
    }
    
    private func selectAllItems(_ selected: Bool) {
        for index in dataScanner.cleanupItems.indices {
            dataScanner.cleanupItems[index].isSelected = selected
        }
    }
}

struct CategoryRowView: View {
    let category: CleanupCategory
    let itemCount: Int
    let totalSize: Int64
    let isSelected: Bool
    let dataScanner: DataScanner
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundColor(category.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(itemCount)개 • \(dataScanner.formatBytes(totalSize))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.2) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

struct CleanupItemRowView: View {
    let item: CleanupItem
    let dataScanner: DataScanner
    
    var body: some View {
        HStack {
            Button(action: {
                if let index = dataScanner.cleanupItems.firstIndex(where: { $0.id == item.id }) {
                    dataScanner.cleanupItems[index].isSelected.toggle()
                }
            }) {
                Image(systemName: item.isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(item.isSelected ? .blue : .secondary)
            }
            .buttonStyle(.plain)
            
            Image(systemName: item.category.icon)
                .foregroundColor(item.category.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(item.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Text(dataScanner.formatBytes(item.size))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(item.isSelected ? Color.blue.opacity(0.1) : Color.clear)
        )
    }
}

#Preview {
    ContentView()
}
import SwiftUI

struct ContentView: View {
    @StateObject private var dataScanner = DataScanner()
    @StateObject private var cleanupManager = CleanupManager()
    @State private var selectedCategory: CleanupCategory? = nil
    @State private var showingCleanupConfirmation = false
    
    var selectedItems: [CleanupItem] {
        dataScanner.cleanupItems.filter { $0.isSelected }
    }
    
    var selectedSize: Int64 {
        selectedItems.reduce(0) { $0 + $1.size }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 헤더
            headerView
            
            Divider()
            
            // 메인 컨텐츠
            HStack(spacing: 0) {
                // 사이드바
                sidebarView
                
                Divider()
                
                // 메인 뷰
                mainContentView
            }
            
            Divider()
            
            // 하단 액션 바
            bottomActionView
        }
        .frame(minWidth: 800, minHeight: 600)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            dataScanner.scanForCleanupItems()
        }
        .sheet(isPresented: $showingCleanupConfirmation) {
            cleanupConfirmationSheet
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "internaldrive")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Mac 데이터 클리너")
                    .font(.title)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if dataScanner.isScanning {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("스캔 중...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Button("다시 스캔") {
                        dataScanner.scanForCleanupItems()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            if !dataScanner.isScanning && dataScanner.totalSize > 0 {
                HStack {
                    Text("총 정리 가능한 데이터:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(dataScanner.formatBytes(dataScanner.totalSize))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
            }
        }
        .padding()
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
                    
                    if selectedSize > 0 {
                        Text("정리 예정 크기: \(dataScanner.formatBytes(selectedSize))")
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
            
            Text("총 \(dataScanner.formatBytes(selectedSize))의 데이터가 삭제됩니다.")
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
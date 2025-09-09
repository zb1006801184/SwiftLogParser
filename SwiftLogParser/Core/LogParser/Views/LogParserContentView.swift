//
//  LogParserContentView.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/8.
//

import SwiftUI
import UniformTypeIdentifiers

/// 日志解析主内容视图 - 符合设计图的 macOS 风格
struct LogParserContentView: View {
    @StateObject private var parserService: LoganParserService
    @State public var logItems: [LoganLogItem] = []
    @State private var filteredLogItems: [LoganLogItem] = []
    @State private var selectedLogItem: LoganLogItem?
    @State private var searchText = ""
    @State private var selectedLogType = "全部日志"
    @State private var showFileImporter = false
    @State private var errorMessage: String?
    @State private var isParseComplete = false
    
    // 新增：解析进度相关状态
    @State private var isParsing = false
    @State private var parseProgress: Double = 0.0
    @State private var currentFileName: String?
    
    private let logTypes = ["全部日志", "性能指标", "错误日志", "警告日志", "信息日志"]
    
    init() {
        let settingsService = SettingsServiceImpl()
        let fileManagerService = FileManagerServiceImpl()
        self._parserService = StateObject(
            wrappedValue: LoganParserService(
                settingsService: settingsService,
                fileManagerService: fileManagerService
            )
        )
    }
    
    // 为预览和测试添加的初始化方法
    init(logItems: [LoganLogItem]) {
        self.init() // 调用主初始化器
        self._logItems = State(initialValue: logItems)
        self._filteredLogItems = State(initialValue: logItems)
    }
    
    var body: some View {
        HSplitView {
            // 左侧：日志列表区域
            VStack(spacing: 0) {
                // 顶部搜索和筛选区域
                searchAndFilterSection
                
                // 日志列表
                logListSection
            }
            .frame(minWidth: 400)
            
            // 右侧：日志详情区域
            logDetailSection
                .frame(minWidth: 300)
        }
        .navigationTitle("日志解析器")
        .onReceive(NotificationCenter.default.publisher(
            for: .fileSelected
        )) { notification in
            if let result = notification.object as? Result<[URL], Error> {
                handleFileSelection(result)
            }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: .fileSelected
        )) { _ in
            showFileImporter = true
        }
        .onReceive(NotificationCenter.default.publisher(
            for: .loadHistoryFile
        )) { notification in
            if let history = notification.object as? ParseHistory {
                loadHistoryFile(history)
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [UTType.data],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
        .alert("解析错误", isPresented: .constant(errorMessage != nil)) {
            Button("确定") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }
    
    // MARK: - 视图组件
    
    /// 顶部搜索和筛选区域
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("日志解析器")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                // 搜索框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("请输入需要搜索的内容", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: searchText) {
                            filterLogs()
                        }
                }
                .frame(maxWidth: .infinity)
                
                // 日志类型选择器
                Picker("日志类型", selection: $selectedLogType) {
                    ForEach(logTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 160)
                .onChange(of: selectedLogType) {
                    filterLogs()
                }
                
                // 当有数据时显示选择文件按钮 - 位置更接近红框位置
                if !logItems.isEmpty {
                    Button(action: {
                        showFileImporter = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 14))
                            Text("选择文件")
                                .font(.system(size: 14, weight: .medium))
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .help("重新选择文件替换当前数据")
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
    }
    
    /// 日志列表区域
    private var logListSection: some View {
        VStack(spacing: 0) {
            // 当正在解析时显示加载进度视图
            if parserService.isParsing || isParsing {
                LoadingProgressView(
                    progress: parserService.parseProgress,
                    fileName: currentFileName
                )
            } else if filteredLogItems.isEmpty && !logItems.isEmpty {
                // 无搜索结果
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("未找到匹配的日志")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("请尝试调整搜索条件或筛选器")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.controlBackgroundColor))
            } else if logItems.isEmpty {
                // 空状态
                emptyStateView
            } else {
                // 日志列表
                List(filteredLogItems) { logItem in
                    LogListItemView(
                        logItem: logItem,
                        isSelected: selectedLogItem?.id == logItem.id
                    ) {
                        selectedLogItem = logItem
                    }
                    .listRowSeparator(.visible)
                }
                .listStyle(PlainListStyle())
            }
        }
    }
    
    /// 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("选择日志文件开始解析")
                .font(.title2)
                .fontWeight(.semibold)
        
            Button("选择文件") {
                showFileImporter = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.controlBackgroundColor))
    }
    
    /// 右侧日志详情区域
    private var logDetailSection: some View {
        VStack(spacing: 0) {
            // 详情标题
            HStack {
                Text("日志详情")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            Divider()
            
            if let selectedLogItem = selectedLogItem {
                LogDetailView(logItem: selectedLogItem)
            } else {
                // 未选择日志时的占位视图
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("选择一条日志查看详情")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.controlBackgroundColor))
            }
        }
    }
    
    // MARK: - 私有方法
    
    /// 处理文件选择
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                // 清除之前的数据和选择状态
                clearCurrentData()
                parseLogFile(at: url)
            }
        case .failure(let error):
            errorMessage = "文件选择失败: \(error.localizedDescription)"
        }
    }
    
    /// 清除当前数据
    private func clearCurrentData() {
        logItems = []
        filteredLogItems = []
        selectedLogItem = nil
        searchText = ""
        selectedLogType = "全部日志"
        isParseComplete = false
        errorMessage = nil
    }
    
    /// 解析日志文件
    private func parseLogFile(at url: URL) {
        Task {
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            
            do {
                isParsing = true
                currentFileName = url.lastPathComponent
                parseProgress = 0.0
                
                let items = try await parserService.parseLogFile(at: url)
                
                await MainActor.run {
                    self.logItems = items
                    self.isParseComplete = true
                    self.errorMessage = nil
                    self.filterLogs()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "解析失败: \(error.localizedDescription)"
                    self.isParseComplete = true
                    self.logItems = []
                    self.filteredLogItems = []
                }
            }
            // 解析完成后重置进度和文件名
            await MainActor.run {
                self.isParsing = false
                self.parseProgress = 0.0
                self.currentFileName = nil
            }
        }
    }
    
    /// 加载历史文件
    private func loadHistoryFile(_ history: ParseHistory) {
        // 清除当前数据
        clearCurrentData()
        
        // 优先使用 jsonFilePath，其次回退到 filePath
        let path = history.jsonFilePath ?? history.filePath
        let url = URL(fileURLWithPath: path)
        
        // 加载JSON文件中的日志数据
        loadLogsFromJSON(at: url)
    }
    
    /// 从JSON文件加载日志数据
    private func loadLogsFromJSON(at url: URL) {
        Task {
            do {
                let data = try Data(contentsOf: url)
                
                // 历史JSON文件的结构为：{ originalFileName, parseTime, logCount, logs: [ {...} ] }
                struct ExportedLogs: Decodable {
                    let logs: [LogDTO]
                }
                struct LogDTO: Decodable {
                    let content: String
                    let flag: String
                    let logTime: String
                    let threadName: String
                    let threadId: String
                    let isMainThread: String
                }
                
                let exported = try JSONDecoder().decode(ExportedLogs.self, from: data)
                let items = exported.logs.map { dto in
                    LoganLogItem(
                        content: dto.content,
                        flag: dto.flag,
                        logTime: dto.logTime,
                        threadName: dto.threadName,
                        threadId: dto.threadId,
                        isMainThread: dto.isMainThread
                    )
                }
                
                await MainActor.run {
                    self.logItems = items
                    self.isParseComplete = true
                    self.errorMessage = nil
                    self.filterLogs()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "加载历史文件失败: \(error.localizedDescription)"
                    self.isParseComplete = true
                    self.logItems = []
                    self.filteredLogItems = []
                }
            }
        }
    }
    
    /// 筛选日志
    private func filterLogs() {
        var filtered = logItems
        
        // 按类型筛选
        if selectedLogType != "全部日志" {
            filtered = filtered.filter { logItem in
                switch selectedLogType {
                case "性能指标":
                    return logItem.content.contains("performance") ||
                           logItem.content.contains("FPS") ||
                           logItem.content.contains("Memory")
                case "错误日志":
                    return logItem.content.contains("error") ||
                           logItem.content.contains("Error") ||
                           logItem.content.contains("ERROR")
                case "警告日志":
                    return logItem.content.contains("warning") ||
                           logItem.content.contains("Warning") ||
                           logItem.content.contains("WARN")
                case "信息日志":
                    return logItem.content.contains("info") ||
                           logItem.content.contains("Info") ||
                           logItem.content.contains("INFO")
                default:
                    return true
                }
            }
        }
        
        // 按搜索文本筛选
        if !searchText.isEmpty {
            filtered = filtered.filter { logItem in
                logItem.content.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        filteredLogItems = filtered
    }
}

#Preview {
    LogParserContentView(logItems: LogMockData.mockLogItems)
        .frame(width: 1000, height: 700)
}

//
//  LogParserView.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/5.
//

import SwiftUI
import UniformTypeIdentifiers

/// Logan 日志解析页面
struct LogParserView: View {
    @StateObject private var parserService: LoganParserService
    @State private var logItems: [LoganLogItem] = []
    @State private var selectedFileUrl: URL?
    @State private var errorMessage: String?
    @State private var showFileImporter = false
    @State private var isParseComplete = false
    
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
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题区域
                headerSection
                
                // 文件选择区域
                fileSelectionSection
                
                // 解析进度区域
                if parserService.isParsing {
                    progressSection
                }
                
                // 解析结果区域
                if !logItems.isEmpty || isParseComplete {
                    resultSection
                }
                
                // 日志列表区域
                if !logItems.isEmpty {
                    logListSection
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Logan 日志解析器")
            .alert("解析错误", isPresented: .constant(errorMessage != nil)) {
                Button("确定") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [UTType.data],
            allowsMultipleSelection: false
        ) { result in
            handleFileSelection(result)
        }
    }
    
    // MARK: - 视图组件
    
    /// 标题区域
    private var headerSection: some View {
        VStack {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Logan 日志解析器")
                .font(.title)
                .fontWeight(.bold)
            
            Text("选择 .logan 文件进行解析")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    /// 文件选择区域
    private var fileSelectionSection: some View {
        VStack(spacing: 16) {
            if let fileUrl = selectedFileUrl {
                HStack {
                    Image(systemName: "doc.fill")
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading) {
                        Text(fileUrl.lastPathComponent)
                            .font(.headline)
                        Text(fileUrl.path)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
            }
            
            HStack(spacing: 16) {
                Button("选择文件") {
                    showFileImporter = true
                }
                .buttonStyle(.borderedProminent)
                
                Button("解析文件") {
                    parseSelectedFile()
                }
                .disabled(selectedFileUrl == nil || parserService.isParsing)
                .buttonStyle(.bordered)
            }
        }
    }
    
    /// 解析进度区域
    private var progressSection: some View {
        VStack(spacing: 12) {
            Text("正在解析文件...")
                .font(.headline)
            
            ProgressView(value: parserService.parseProgress)
                .progressViewStyle(LinearProgressViewStyle())
                .frame(maxWidth: 300)
            
            Text("\(Int(parserService.parseProgress * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    /// 解析结果区域
    private var resultSection: some View {
        VStack(spacing: 12) {
            if isParseComplete && !logItems.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("解析完成")
                            .font(.headline)
                            .foregroundColor(.green)
                        
                        Text("共解析 \(logItems.count) 条日志")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            } else if isParseComplete && logItems.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("解析完成")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text("未找到有效的日志条目")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    /// 日志列表区域
    private var logListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("解析结果")
                    .font(.headline)
                
                Spacer()
                
                Text("共 \(logItems.count) 条")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            List(Array(logItems.prefix(100).enumerated()), id: \.offset) { 
                index, item in
                LogItemRow(item: item, index: index)
            }
            .frame(maxHeight: 300)
            .border(Color(.separatorColor))
            
            if logItems.count > 100 {
                Text("仅显示前 100 条日志，完整结果已导出到应用文档目录")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
    }
    
    // MARK: - 私有方法
    
    /// 处理文件选择
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                selectedFileUrl = url
                errorMessage = nil
                isParseComplete = false
                logItems = []
            }
        case .failure(let error):
            errorMessage = "文件选择失败: \(error.localizedDescription)"
        }
    }
    
    /// 解析选中的文件
    private func parseSelectedFile() {
        guard let fileUrl = selectedFileUrl else { return }
        
        // 开启安全作用域访问，解决沙盒导致的文件读取权限问题
        Task {
            let accessed = fileUrl.startAccessingSecurityScopedResource()
            defer { if accessed { fileUrl.stopAccessingSecurityScopedResource() } }
            do {
                let items = try await parserService.parseLogFile(at: fileUrl)
                await MainActor.run {
                    self.logItems = items
                    self.isParseComplete = true
                    self.errorMessage = nil
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "解析失败: \(error.localizedDescription)"
                    self.isParseComplete = true
                    self.logItems = []
                }
            }
        }
    }
}

/// 日志条目行视图
struct LogItemRow: View {
    let item: LoganLogItem
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("#\(index + 1)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .leading)
                
                Text(flagDescription)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(flagColor)
                    .foregroundColor(.white)
                    .cornerRadius(4)
                
                Spacer()
                
                Text(formattedTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(item.content)
                .font(.system(.body, design: .monospaced))
                .lineLimit(3)
                .truncationMode(.tail)
            
            HStack {
                Text("线程: \(item.threadName)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("ID: \(item.threadId)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if item.isMainThread == "true" {
                    Text("主线程")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
    
    private var flagDescription: String {
        switch item.flag {
        case "1": return "VERBOSE"
        case "2": return "DEBUG"
        case "3": return "INFO"
        case "4": return "WARN"
        case "5": return "ERROR"
        default: return "INFO"
        }
    }
    
    private var flagColor: Color {
        switch item.flag {
        case "1": return .gray
        case "2": return .blue
        case "3": return .green
        case "4": return .orange
        case "5": return .red
        default: return .green
        }
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        
        if let date = ISO8601DateFormatter().date(from: item.logTime) {
            return formatter.string(from: date)
        }
        return item.logTime
    }
}

#Preview {
    LogParserView()
}
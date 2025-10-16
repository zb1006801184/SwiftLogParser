//
//  LogQueryViewModel.swift
//  SwiftLogParser
//
//  Created by AI Assistant on 2025/10/15.
//

import Foundation
import Combine
import AppKit

#if canImport(Moya)

/// 日志查询视图模型
class LogQueryViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// 用户ID输入
    @Published var userId: String = ""
    
    /// 开始时间
    @Published var startTime: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    
    /// 结束时间
    @Published var endTime: Date = Date()
    
    /// 文件地址列表
    @Published var fileItems: [LogFileItem] = []
    
    /// 是否正在加载
    @Published var isLoading: Bool = false
    
    /// 错误信息
    @Published var errorMessage: String?
    
    /// 是否显示错误提示
    @Published var showError: Bool = false
    
    /// 是否显示复制成功提示
    @Published var showCopySuccess: Bool = false
    
    // MARK: - Private Properties
    
    private let logQueryService: LogQueryService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(logQueryService: LogQueryService = LogQueryService()) {
        self.logQueryService = logQueryService
    }
    
    // MARK: - Public Methods
    
    /// 查询日志文件列表
    @MainActor
    func fetchLogFiles() {
        guard !userId.isEmpty else {
            showErrorMessage("请输入用户ID")
            return
        }
        
        guard startTime <= endTime else {
            showErrorMessage("开始时间不能晚于结束时间")
            return
        }
        
        Task {
            await performFetchLogFiles()
        }
    }
    
    /// 复制文件URL到剪贴板
    /// - Parameter url: 文件URL
    @MainActor
    func copyFileUrl(_ url: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(url, forType: .string)
        showCopySuccess = true
    }
    
    // MARK: - Private Methods
    
    /// 执行查询日志文件列表
    @MainActor
    private func performFetchLogFiles() async {
        isLoading = true
        errorMessage = nil
        fileItems = []
        
        do {
            let urls = try await logQueryService.queryLogFiles(
                userId: userId,
                startTime: startTime,
                endTime: endTime
            )
            
            fileItems = urls.map { LogFileItem(url: $0) }
            
            if fileItems.isEmpty {
                showErrorMessage("未找到符合条件的日志文件")
            }
        } catch {
            showErrorMessage(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    /// 显示错误信息
    /// - Parameter message: 错误信息
    @MainActor
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    /// 格式化日期为字符串
    /// - Parameter date: 日期
    /// - Returns: 格式化后的字符串
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

#endif

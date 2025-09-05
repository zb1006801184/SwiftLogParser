//
//  main_view_model.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/5.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class MainViewModel: ObservableObject {
    @Published var logItems: [LoganLogItem] = []
    @Published var filteredLogItems: [LoganLogItem] = []
    @Published var searchText = ""
    @Published var selectedLogType = "全部日志"
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var currentFileName = ""
    @Published var parseProgress: Double = 0.0
    
    // 服务依赖
    private let loganParserService: LoganParserService
    private let settingsService: SettingsService
    private let fileManagerService: FileManagerService
    
    // Combine 订阅
    private var cancellables = Set<AnyCancellable>()
    
    // 日志类型选项
    let logTypeOptions = ["全部日志", "2", "3", "4", "5", "6", "7", "8"]
    
    init() {
        self.settingsService = SettingsService()
        self.fileManagerService = FileManagerService()
        self.loganParserService = LoganParserService(
            settingsService: settingsService,
            fileManagerService: fileManagerService
        )
        
        setupBindings()
    }
    
    // 设置数据绑定
    private func setupBindings() {
        // 监听搜索文本和筛选类型变化
        Publishers.CombineLatest($searchText, $selectedLogType)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] searchText, logType in
                self?.filterLogs(searchText: searchText, logType: logType)
            }
            .store(in: &cancellables)
        
        // 监听解析进度
        loganParserService.$parseProgress
            .receive(on: DispatchQueue.main)
            .assign(to: \.parseProgress, on: self)
            .store(in: &cancellables)
        
        // 监听解析状态
        loganParserService.$isParsing
            .receive(on: DispatchQueue.main)
            .assign(to: \MainViewModel.isLoading, on: self)
            .store(in: &cancellables)
    }
    
    // 选择并解析文件
    func selectAndParseFile() {
        guard let fileURL = fileManagerService.selectLogFile() else {
            return
        }
        
        parseFile(at: fileURL)
    }
    
    // 解析文件
    func parseFile(at url: URL) {
        currentFileName = url.lastPathComponent
        
        Task {
            do {
                let parsedLogs = try await loganParserService.parseLogFile(at: url)
                
                await MainActor.run {
                    self.logItems = parsedLogs
                    self.filterLogs(searchText: searchText, logType: selectedLogType)
                }
                
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.showError = true
                }
            }
        }
    }
    
    // 筛选日志
    private func filterLogs(searchText: String, logType: String) {
        var filtered = logItems
        
        // 按类型筛选
        if logType != "全部日志" {
            filtered = filtered.filter { $0.matchesFilter(logType) }
        }
        
        // 按关键词搜索
        if !searchText.isEmpty {
            filtered = filtered.filter { $0.containsKeyword(searchText) }
        }
        
        filteredLogItems = filtered
    }
    
    // 导出为文本文件
    func exportAsText() {
        guard !logItems.isEmpty else { return }
        
        Task {
            do {
                try await fileManagerService.exportAsTextFile(
                    logItems: logItems,
                    originalFileName: currentFileName
                )
            } catch {
                await MainActor.run {
                    self.errorMessage = "导出失败: \(error.localizedDescription)"
                    self.showError = true
                }
            }
        }
    }
    
    // 清空日志
    func clearLogs() {
        logItems.removeAll()
        filteredLogItems.removeAll()
        currentFileName = ""
        searchText = ""
        selectedLogType = "全部日志"
    }
    
    // 获取日志统计信息
    var logStatistics: (total: Int, filtered: Int, types: [String: Int]) {
        let total = logItems.count
        let filtered = filteredLogItems.count
        
        var typeCount: [String: Int] = [:]
        for item in logItems {
            let type = item.logTypeDescription
            typeCount[type, default: 0] += 1
        }
        
        return (total: total, filtered: filtered, types: typeCount)
    }
    
    // 获取设置服务（供设置页面使用）
    func getSettingsService() -> SettingsService {
        return settingsService
    }
}

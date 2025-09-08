//
//  HistoryViewModel.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/8.
//

import Foundation
import SwiftUI

/// 历史记录视图模型
class HistoryViewModel: ObservableObject {
    @Published var histories: [ParseHistory] = []
    @Published var isLoading = false
    @Published var showingClearAlert = false
    
    private let historyService: HistoryServiceProtocol
    
    init(historyService: HistoryServiceProtocol = HistoryService()) {
        self.historyService = historyService
        loadHistories()
    }
    
    /// 加载历史记录
    func loadHistories() {
        histories = historyService.getHistories()
    }
    
    /// 删除历史记录
    func deleteHistory(id: String) {
        historyService.deleteHistory(id: id)
        loadHistories()
    }
    
    /// 清空所有历史记录
    func clearAllHistories() {
        historyService.clearAllHistories()
        loadHistories()
    }
    
    /// 添加历史记录
    func addHistory(_ history: ParseHistory) {
        historyService.addHistory(history)
        loadHistories()
    }
    
    /// 显示清空确认弹窗
    func showClearAlert() {
        showingClearAlert = true
    }
    
    /// 获取历史记录数量
    var historyCount: Int {
        return histories.count
    }
    
    /// 检查是否有历史记录
    var hasHistories: Bool {
        return !histories.isEmpty
    }
}
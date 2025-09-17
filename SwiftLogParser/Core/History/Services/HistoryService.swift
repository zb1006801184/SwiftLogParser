//
//  HistoryService.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/8.
//

import Foundation

/// 历史记录服务协议
protocol HistoryServiceProtocol {
    func addHistory(_ history: ParseHistory)
    func getHistories() -> [ParseHistory]
    func deleteHistory(id: String)
    func clearAllHistories()
}

/// 历史记录服务实现
class HistoryService: HistoryServiceProtocol {
    // 单例实例，确保全局共享同一份内存数据
    static let shared = HistoryService()

    private var histories: [ParseHistory] = []
    
    private let userDefaults = UserDefaults.standard
    private let historyKey = "parse_histories"
    
    init() {
        loadHistories()
    }
    
    /// 添加历史记录
    func addHistory(_ history: ParseHistory) {
        histories.insert(history, at: 0)
        saveHistories()
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .historyUpdated, object: nil)
        }
    }
    
    /// 获取历史记录
    func getHistories() -> [ParseHistory] {
        return histories
    }
    
    /// 删除指定历史记录
    func deleteHistory(id: String) {
        if let target = histories.first(where: { $0.id == id }) {
            // 删除关联的 JSON 文件（若存在）
            let path = target.jsonFilePath ?? target.filePath
            if FileManager.default.fileExists(atPath: path) {
                try? FileManager.default.removeItem(atPath: path)
            }
        }
        histories.removeAll { $0.id == id }
        saveHistories()
        NotificationCenter.default.post(name: .historyUpdated, object: nil)
    }
    
    /// 清空所有历史记录
    func clearAllHistories() {
        // 尝试删除所有关联文件
        for item in histories {
            let path = item.jsonFilePath ?? item.filePath
            if FileManager.default.fileExists(atPath: path) {
                try? FileManager.default.removeItem(atPath: path)
            }
        }
        histories.removeAll()
        saveHistories()
        NotificationCenter.default.post(name: .historyUpdated, object: nil)
    }
    
    // MARK: - Private Methods
    
    /// 从UserDefaults加载历史记录
    private func loadHistories() {
        guard let data = userDefaults.data(forKey: historyKey),
              let decodedHistories = try? JSONDecoder().decode(
                [ParseHistory].self,
                from: data
              ) else {
            return
        }
        histories = decodedHistories
    }
    
    /// 保存历史记录到UserDefaults
    private func saveHistories() {
        guard let encodedData = try? JSONEncoder().encode(histories) else {
            return
        }
        userDefaults.set(encodedData, forKey: historyKey)
    }
    
    // 过去的示例数据注入逻辑已移除，改为只加载真实持久化数据
}

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
    private var histories: [ParseHistory] = []
    
    private let userDefaults = UserDefaults.standard
    private let historyKey = "parse_histories"
    
    init() {
        loadHistories()
        // 如果没有历史记录，添加一些示例数据用于测试
        if histories.isEmpty {
            addSampleData()
        }
    }
    
    /// 添加历史记录
    func addHistory(_ history: ParseHistory) {
        histories.insert(history, at: 0) // 最新的记录在前面
        saveHistories()
    }
    
    /// 获取历史记录
    func getHistories() -> [ParseHistory] {
        return histories
    }
    
    /// 删除指定历史记录
    func deleteHistory(id: String) {
        histories.removeAll { $0.id == id }
        saveHistories()
    }
    
    /// 清空所有历史记录
    func clearAllHistories() {
        histories.removeAll()
        saveHistories()
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
    
    /// 添加示例数据用于测试
    private func addSampleData() {
        let sampleHistories = [
            ParseHistory(
                filePath: "/Users/zhubiao/Documents/logs/app_log_2025_09_08.logan",
                fileName: "app_log_2025_09_08.logan",
                parseTime: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
                fileSize: 2048576,
                logCount: 1250,
                isSuccess: true,
                errorMessage: nil
            ),
            ParseHistory(
                filePath: "/Users/zhubiao/Documents/logs/debug_log_2025_09_07.logan",
                fileName: "debug_log_2025_09_07.logan",
                parseTime: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
                fileSize: 1536000,
                logCount: 890,
                isSuccess: true,
                errorMessage: nil
            ),
            ParseHistory(
                filePath: "/Users/zhubiao/Documents/logs/error_log_2025_09_06.logan",
                fileName: "error_log_2025_09_06.logan",
                parseTime: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
                fileSize: 512000,
                logCount: 0,
                isSuccess: false,
                errorMessage: "AES 解密失败：密钥不匹配"
            ),
            ParseHistory(
                filePath: "/Users/zhubiao/Documents/logs/system_log_2025_09_05.logan",
                fileName: "system_log_2025_09_05.logan",
                parseTime: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(),
                fileSize: 3072000,
                logCount: 2100,
                isSuccess: true,
                errorMessage: nil
            ),
            ParseHistory(
                filePath: "/Users/zhubiao/Documents/logs/crash_log_2025_09_04.logan",
                fileName: "crash_log_2025_09_04.logan",
                parseTime: Calendar.current.date(byAdding: .day, value: -4, to: Date()) ?? Date(),
                fileSize: 768000,
                logCount: 0,
                isSuccess: false,
                errorMessage: "GZIP 解压缩失败：数据格式错误"
            )
        ]
        
        for history in sampleHistories {
            histories.append(history)
        }
        saveHistories()
    }
}

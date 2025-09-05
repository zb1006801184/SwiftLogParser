//
//  logan_log_item.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/09/05.
//

import Foundation
import SwiftUI

// MARK: - Logan 日志条目数据模型
struct LoganLogItem: Codable, Identifiable, Equatable, Hashable {
    // MARK: - 属性
    
    /// 唯一标识符
    let id = UUID()
    
    /// 日志内容 (JSON 字段: "c")
    let content: String?
    
    /// 日志类型标识 (JSON 字段: "f")
    /// 2:调试, 3:信息/埋点, 4:错误, 5:警告, 6:严重错误, 7:网络请求, 8:性能指标
    let flag: String?
    
    /// 日志时间 (JSON 字段: "l") - 毫秒时间戳
    let logTime: String?
    
    /// 线程名称 (JSON 字段: "n")
    let threadName: String?
    
    /// 线程ID (JSON 字段: "i")
    let threadId: String?
    
    /// 是否主线程 (JSON 字段: "m")
    let isMainThread: String?
    
    // MARK: - 初始化
    
    init(content: String? = nil,
         flag: String? = "3",
         logTime: String? = nil,
         threadName: String? = nil,
         threadId: String? = nil,
         isMainThread: String? = nil) {
        self.content = content
        self.flag = flag
        self.logTime = logTime
        self.threadName = threadName
        self.threadId = threadId
        self.isMainThread = isMainThread
    }
    
    // MARK: - 计算属性
    
    /// 格式化的日志时间
    var formattedLogTime: String {
        guard let logTime = logTime else { return "未知时间" }
        
        // 尝试解析毫秒时间戳
        if let timestamp = Int64(logTime) {
            let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            formatter.locale = Locale(identifier: "zh_CN")
            return formatter.string(from: date)
        }
        
        return logTime
    }
    
    /// 日志类型描述
    var logTypeDescription: String {
        return logTypeMapping[flag ?? "3"] ?? "其他"
    }
    
    /// 日志类型颜色
    var logTypeColor: Color {
        return logTypeColors[flag ?? "3"] ?? .gray
    }
    
    /// 安全的日志内容（防止为空）
    var safeContent: String {
        return content?.isEmpty == false ? content! : "无内容"
    }
    
    /// 安全的线程名称
    var safeThreadName: String {
        return threadName?.isEmpty == false ? threadName! : "未知线程"
    }
    
    /// 是否为主线程
    var isMainThreadBool: Bool {
        return isMainThread == "1" || isMainThread?.lowercased() == "true"
    }
    
    // MARK: - 方法
    
    /// 搜索匹配方法
    /// - Parameter keyword: 搜索关键词
    /// - Returns: 是否匹配
    func containsKeyword(_ keyword: String) -> Bool {
        guard !keyword.isEmpty else { return true }
        
        let lowerKeyword = keyword.lowercased()
        return (content?.lowercased().contains(lowerKeyword) ?? false) ||
               (logTime?.lowercased().contains(lowerKeyword) ?? false) ||
               (threadName?.lowercased().contains(lowerKeyword) ?? false) ||
               (threadId?.lowercased().contains(lowerKeyword) ?? false) ||
               (logTypeDescription.lowercased().contains(lowerKeyword))
    }
    
    /// 筛选匹配方法
    /// - Parameter filterType: 筛选类型
    /// - Returns: 是否匹配筛选条件
    func matchesFilter(_ filterType: String) -> Bool {
        guard !filterType.isEmpty && filterType != "全部日志" else { return true }
        return flag == filterType
    }
    
    /// 获取详细信息字典
    /// - Returns: 包含所有字段的详细信息
    func getDetailInfo() -> [String: String] {
        return [
            "内容": safeContent,
            "时间": formattedLogTime,
            "类型": logTypeDescription,
            "线程名称": safeThreadName,
            "线程ID": threadId ?? "未知",
            "主线程": isMainThreadBool ? "是" : "否"
        ]
    }
    
    // MARK: - Codable 实现
    
    /// 自定义编码键，对应 Logan JSON 字段
    enum CodingKeys: String, CodingKey {
        case content = "c"
        case flag = "f"
        case logTime = "l"
        case threadName = "n"
        case threadId = "i"
        case isMainThread = "m"
    }
    
    // MARK: - Equatable 实现
    
    static func == (lhs: LoganLogItem, rhs: LoganLogItem) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Hashable 实现
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - 扩展方法

extension LoganLogItem {
    /// 创建测试用的日志条目
    static func createSample() -> LoganLogItem {
        return LoganLogItem(
            content: "这是一个测试日志条目",
            flag: "3",
            logTime: String(Int(Date().timeIntervalSince1970 * 1000)),
            threadName: "main",
            threadId: "1",
            isMainThread: "1"
        )
    }
    
    /// 从 JSON 字典创建日志条目
    /// - Parameter jsonDict: JSON 字典
    /// - Returns: Logan 日志条目，失败返回 nil
    static func fromJsonDict(_ jsonDict: [String: Any]) -> LoganLogItem? {
        let content = jsonDict[LoganConstants.JsonFields.content] as? String
        let flag = jsonDict[LoganConstants.JsonFields.flag] as? String ?? "3"
        
        // 处理时间字段
        var logTime: String?
        if let timeValue = jsonDict[LoganConstants.JsonFields.logTime] {
            if let stringValue = timeValue as? String {
                logTime = stringValue
            } else if let numberValue = timeValue as? NSNumber {
                logTime = String(numberValue.int64Value)
            }
        }
        
        let threadName = jsonDict[LoganConstants.JsonFields.threadName] as? String
        let threadId = jsonDict[LoganConstants.JsonFields.threadId] as? String
        let isMainThread = jsonDict[LoganConstants.JsonFields.isMainThread] as? String
        
        return LoganLogItem(
            content: content,
            flag: flag,
            logTime: logTime,
            threadName: threadName,
            threadId: threadId,
            isMainThread: isMainThread
        )
    }
}

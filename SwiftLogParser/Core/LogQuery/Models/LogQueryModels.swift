//
//  LogQueryModels.swift
//  SwiftLogParser
//
//  Created by AI Assistant on 2025/10/15.
//

import Foundation

// MARK: - 日志文件地址响应模型

/// 日志查询响应
struct LogQueryResponse: Codable {
    let code: Int
    let message: String?
    let data: [String]?  // 文件地址列表
}

// MARK: - 日志文件项模型

/// 日志文件项（用于UI展示）
struct LogFileItem: Identifiable {
    let id: UUID
    let url: String
    let fileName: String
    
    init(url: String) {
        self.id = UUID()
        self.url = url
        // 从URL中提取文件名
        if let urlComponents = URLComponents(string: url),
           let path = urlComponents.path.split(separator: "/").last {
            self.fileName = String(path)
        } else {
            self.fileName = url
        }
    }
}

// MARK: - 日志内容项模型（用于展示解析后的日志）

/// 远程日志内容项
struct RemoteLogItem: Identifiable {
    let id: UUID
    let content: String
    let timestamp: String
    let level: String
    
    init(content: String, timestamp: String = "", level: String = "INFO") {
        self.id = UUID()
        self.content = content
        self.timestamp = timestamp
        self.level = level
    }
}

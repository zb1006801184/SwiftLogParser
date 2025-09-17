//
//  DemoModels.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/15.
//

import Foundation

// MARK: - 演示用数据模型

/// 演示用户模型
public struct DemoUser: Codable, Identifiable {
    public let id: String
    let name: String
    let email: String
    let avatar: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case avatar
        case createdAt = "created_at"
    }
}

/// 演示日志模型
public struct DemoLog: Codable, Identifiable {
    public let id: String
    let level: LogLevel
    let message: String
    let timestamp: Date
    let source: String
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case level
        case message
        case timestamp
        case source
        case metadata
    }
}

/// 日志级别枚举
public enum LogLevel: String, Codable, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case fatal = "FATAL"
    
    /// 获取日志级别的显示颜色
    var color: String {
        switch self {
        case .debug:
            return "blue"
        case .info:
            return "green"
        case .warning:
            return "orange"
        case .error:
            return "red"
        case .fatal:
            return "purple"
        }
    }
}

/// 演示响应模型
public struct DemoResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let code: Int
}

/// 分页响应模型
public struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let pagination: PaginationInfo
}

/// 分页信息
public struct PaginationInfo: Codable {
    let currentPage: Int
    let totalPages: Int
    let totalItems: Int
    let itemsPerPage: Int
    
    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case totalPages = "total_pages"
        case totalItems = "total_items"
        case itemsPerPage = "items_per_page"
    }
}

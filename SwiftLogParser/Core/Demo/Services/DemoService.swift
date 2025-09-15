//
//  DemoService.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/15.
//

import Foundation
#if canImport(Moya)
import Moya

/// 演示服务类：对外暴露领域方法，内部使用 NetworkProvider 请求与解码
public final class DemoService {
    
    /// Provider（复用全局配置：统一 headers、超时、日志）
    private let provider = NetworkProvider<DemoAPI>()
    
    // MARK: - 用户相关方法
    
    /// 获取用户信息（演示）
    /// - Parameter id: 用户 ID
    /// - Returns: 解码后的用户对象
    func fetchUser(id: String) async throws -> DemoUser {
        try await provider.requestDecodable(DemoUser.self, target: .user(id: id))
    }
    
    /// 获取用户列表（分页）
    /// - Parameters:
    ///   - page: 页码
    ///   - limit: 每页数量
    /// - Returns: 分页用户列表
    func fetchUsers(page: Int = 1, limit: Int = 20) async throws -> PaginatedResponse<DemoUser> {
        try await provider.requestDecodable(PaginatedResponse<DemoUser>.self, target: .users(page: page, limit: limit))
    }
    
    // MARK: - 日志相关方法
    
    /// 获取日志列表
    /// - Parameters:
    ///   - page: 页码
    ///   - limit: 每页数量
    ///   - level: 日志级别过滤（可选）
    /// - Returns: 分页日志列表
    func fetchLogs(page: Int = 1, limit: Int = 20, level: LogLevel? = nil) async throws -> PaginatedResponse<DemoLog> {
        try await provider.requestDecodable(PaginatedResponse<DemoLog>.self, target: .logs(page: page, limit: limit, level: level))
    }
    
    /// 获取特定日志详情
    /// - Parameter id: 日志 ID
    /// - Returns: 日志详情
    func fetchLog(id: String) async throws -> DemoLog {
        try await provider.requestDecodable(DemoLog.self, target: .log(id: id))
    }
    
    /// 上传日志文件
    /// - Parameter fileData: 日志文件数据
    /// - Returns: 上传结果
    func uploadLog(fileData: Data) async throws -> DemoResponse<String> {
        try await provider.requestDecodable(DemoResponse<String>.self, target: .uploadLog(file: fileData))
    }
    
    /// 搜索日志
    /// - Parameters:
    ///   - query: 搜索关键词
    ///   - page: 页码
    ///   - limit: 每页数量
    /// - Returns: 搜索结果
    func searchLogs(query: String, page: Int = 1, limit: Int = 20) async throws -> PaginatedResponse<DemoLog> {
        try await provider.requestDecodable(PaginatedResponse<DemoLog>.self, target: .searchLogs(query: query, page: page, limit: limit))
    }
    
    // MARK: - 模拟数据方法（用于演示）
    
    /// 生成模拟用户数据
    /// - Returns: 模拟用户列表
    func generateMockUsers() -> [DemoUser] {
        return [
            DemoUser(
                id: "1",
                name: "张三",
                email: "zhangsan@example.com",
                avatar: "https://example.com/avatar1.jpg",
                createdAt: Date()
            ),
            DemoUser(
                id: "2",
                name: "李四",
                email: "lisi@example.com",
                avatar: "https://example.com/avatar2.jpg",
                createdAt: Date().addingTimeInterval(-86400)
            ),
            DemoUser(
                id: "3",
                name: "王五",
                email: "wangwu@example.com",
                avatar: nil,
                createdAt: Date().addingTimeInterval(-172800)
            )
        ]
    }
    
    /// 生成模拟日志数据
    /// - Returns: 模拟日志列表
    func generateMockLogs() -> [DemoLog] {
        return [
            DemoLog(
                id: "1",
                level: .info,
                message: "用户登录成功",
                timestamp: Date(),
                source: "AuthService",
                metadata: ["userId": "123", "ip": "192.168.1.1"]
            ),
            DemoLog(
                id: "2",
                level: .warning,
                message: "网络连接超时",
                timestamp: Date().addingTimeInterval(-300),
                source: "NetworkService",
                metadata: ["url": "https://api.example.com", "timeout": "30s"]
            ),
            DemoLog(
                id: "3",
                level: .error,
                message: "数据库连接失败",
                timestamp: Date().addingTimeInterval(-600),
                source: "DatabaseService",
                metadata: ["error": "Connection refused", "retry": "3"]
            )
        ]
    }
}

#endif

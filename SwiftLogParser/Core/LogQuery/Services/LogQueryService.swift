//
//  LogQueryService.swift
//  SwiftLogParser
//
//  Created by AI Assistant on 2025/10/15.
//

import Foundation
#if canImport(Moya)
import Moya

/// 日志查询服务
class LogQueryService {
    private let provider: NetworkProvider<LogQueryAPI>
    
    init(provider: NetworkProvider<LogQueryAPI> = NetworkProvider<LogQueryAPI>()) {
        self.provider = provider
    }
    
    /// 查询日志文件地址列表
    /// - Parameters:
    ///   - userId: 用户ID
    ///   - startTime: 开始时间
    ///   - endTime: 结束时间
    /// - Returns: 文件地址列表
    func queryLogFiles(userId: String, startTime: Date, endTime: Date) async throws -> [String] {
        // 将Date转换为毫秒时间戳
        let startTimeMs = Int64(startTime.timeIntervalSince1970 * 1000)
        let endTimeMs = Int64(endTime.timeIntervalSince1970 * 1000)
        
        print("开始查询日志文件: userId=\(userId), startTime=\(startTimeMs), endTime=\(endTimeMs)")
        
        let response = try await provider.requestDecodable(
            LogQueryResponse.self,
            target: .queryLogFiles(userId: userId, startTime: startTimeMs, endTime: endTimeMs)
        )
        
        guard response.code == 200 else {
            throw LogQueryError.requestFailed(message: response.message ?? "请求失败")
        }
        
        guard let data = response.data else {
            throw LogQueryError.emptyData
        }
        
        print("查询成功，获取到 \(data.count) 个文件地址")
        return data
    }
    
    /// 下载并解析日志文件
    /// - Parameter url: 文件URL
    /// - Returns: 日志内容
    func downloadAndParseLog(from url: String) async throws -> String {
        guard let fileURL = URL(string: url) else {
            throw LogQueryError.invalidURL
        }
        
        print("开始下载日志文件: \(url)")
        
        let (data, response) = try await URLSession.shared.data(from: fileURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw LogQueryError.downloadFailed
        }
        
        print("下载成功，文件大小: \(data.count) 字节")
        
        // 尝试将数据转换为字符串
        if let content = String(data: data, encoding: .utf8) {
            return content
        } else {
            throw LogQueryError.decodingFailed
        }
    }
}

// MARK: - 日志查询错误定义

enum LogQueryError: Error, LocalizedError {
    case requestFailed(message: String)
    case emptyData
    case invalidURL
    case downloadFailed
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .requestFailed(let message):
            return "请求失败: \(message)"
        case .emptyData:
            return "返回数据为空"
        case .invalidURL:
            return "无效的URL地址"
        case .downloadFailed:
            return "文件下载失败"
        case .decodingFailed:
            return "文件解码失败"
        }
    }
}

#endif

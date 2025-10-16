//
//  LogQueryAPI.swift
//  SwiftLogParser
//
//  Created by AI Assistant on 2025/10/15.
//

import Foundation
#if canImport(Moya)
import Moya

/// 日志查询 API 定义
enum LogQueryAPI: APITarget {
    /// 根据ID获取日志文件地址列表
    /// - Parameters:
    ///   - userId: 用户ID
    ///   - startTime: 开始时间（毫秒时间戳）
    ///   - endTime: 结束时间（毫秒时间戳）
    case queryLogFiles(userId: String, startTime: Int64, endTime: Int64)
    
    /// 路径
    var path: String {
        switch self {
        case .queryLogFiles:
            return "/api/education/retrieve/log/query.json"
        }
    }
    
    /// 请求方法
    var method: Moya.Method {
        switch self {
        case .queryLogFiles:
            return .get
        }
    }
    
    /// 请求任务
    var task: Moya.Task {
        switch self {
        case .queryLogFiles(let userId, let startTime, let endTime):
            return .requestParameters(
                parameters: [
                    "userId": userId,
                    "startTime": startTime,
                    "endTime": endTime
                ],
                encoding: URLEncoding.default
            )
        }
    }
}

#endif

//
//  DemoAPI.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/15.
//

import Foundation
#if canImport(Moya)
import Moya

/// 演示 API：展示如何定义一个基于 Moya 的接口枚举
enum DemoAPI: APITarget {
    /// 获取用户信息
    case user(id: String)
    
    /// 获取用户列表（分页）
    case users(page: Int, limit: Int)
    
    /// 获取日志列表
    case logs(page: Int, limit: Int, level: LogLevel?)
    
    /// 获取特定日志详情
    case log(id: String)
    
    /// 上传日志文件
    case uploadLog(file: Data)
    
    /// 搜索日志
    case searchLogs(query: String, page: Int, limit: Int)
    
    /// 路径
    var path: String {
        switch self {
        case .user(let id):
            return "/users/\(id)"
        case .users:
            return "/users"
        case .logs:
            return "/logs"
        case .log(let id):
            return "/logs/\(id)"
        case .uploadLog:
            return "/logs/upload"
        case .searchLogs:
            return "/logs/search"
        }
    }
    
    /// 请求方法
    var method: Moya.Method {
        switch self {
        case .user, .users, .logs, .log, .searchLogs:
            return .get
        case .uploadLog:
            return .post
        }
    }
    
    /// 请求任务（参数、Body 等）
    var task: Moya.Task {
        switch self {
        case .user:
            return .requestPlain
            
        case .users(let page, let limit):
            return .requestParameters(
                parameters: [
                    "page": page,
                    "limit": limit
                ],
                encoding: URLEncoding.default
            )
            
        case .logs(let page, let limit, let level):
            var parameters: [String: Any] = [
                "page": page,
                "limit": limit
            ]
            if let level = level {
                parameters["level"] = level.rawValue
            }
            return .requestParameters(
                parameters: parameters,
                encoding: URLEncoding.default
            )
            
        case .log:
            return .requestPlain
            
        case .uploadLog(let file):
            let formData = MultipartFormData(
                provider: .data(file),
                name: "logfile",
                fileName: "logfile.log",
                mimeType: "text/plain"
            )
            return .uploadMultipart([formData])
            
        case .searchLogs(let query, let page, let limit):
            return .requestParameters(
                parameters: [
                    "q": query,
                    "page": page,
                    "limit": limit
                ],
                encoding: URLEncoding.default
            )
        }
    }
    
    /// 请求头（可选，会与全局配置合并）
    var headers: [String: String]? {
        switch self {
        case .uploadLog:
            return ["Content-Type": "multipart/form-data"]
        default:
            return nil
        }
    }
}

#endif

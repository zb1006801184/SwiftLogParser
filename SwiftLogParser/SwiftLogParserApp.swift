//
//  SwiftLogParserApp.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/8.
//

import SwiftUI
#if canImport(Moya)
import Moya
#endif

@main
struct SwiftLogParserApp: App {

    init() {
        Network.sharedConfig = NetworkConfig(
            baseURL: URL(string: "https://api.example.com")!,
            globalHeadersProvider: {
                [
                    "Accept": "application/json",
                ]
            },
            timeout: 20,
            isLoggingEnabled: true
        )
    }

    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}

// MARK: - 演示用 API 与服务（示例）
#if canImport(Moya)

/// 演示 API：展示如何定义一个基于 Moya 的接口枚举
enum DemoAPI: APITarget {
    /// 获取用户信息
    case user(id: String)

    /// 路径
    var path: String {
        switch self {
        case .user(let id):
            return "/users/\(id)"
        }
    }

    /// 请求方法
    var method: Moya.Method {
        switch self {
        case .user:
            return .get
        }
    }

    /// 请求任务（参数、Body 等）
    var task: Moya.Task {
        switch self {
        case .user:
            return .requestPlain
        }
    }
}

/// 演示服务类：对外暴露领域方法，内部使用 NetworkProvider 请求与解码
final class DemoService {
    /// 领域模型（演示）
    struct User: Decodable {
        let id: String
        let name: String
    }

    /// Provider（复用全局配置：统一 headers、超时、日志）
    private let provider = NetworkProvider<DemoAPI>()

    /// 获取用户信息（演示）
    /// - Parameter id: 用户 ID
    /// - Returns: 解码后的用户对象
    func fetchUser(id: String) async throws -> User {
        try await provider.requestDecodable(User.self, target: .user(id: id))
    }
}
#endif

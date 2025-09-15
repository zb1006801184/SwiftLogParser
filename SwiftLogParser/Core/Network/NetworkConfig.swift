import Foundation

/// 网络层全局配置（统一请求头、超时时间、日志开关等）
public struct NetworkConfig {
    /// 基础域名（全局统一）
    public var baseURL: URL
    /// 动态全局请求头提供者（例如携带 Token 等）
    public var globalHeadersProvider: () -> [String: String]
    /// 请求超时时间（秒）
    public var timeout: TimeInterval
    /// 是否开启网络日志
    public var isLoggingEnabled: Bool
    /// 额外插件（Moya 插件容器，使用 Any 以移除对 Moya 的强依赖）
    public var plugins: [Any]

    public init(
        baseURL: URL = URL(string: "https://example.com")!,
        globalHeadersProvider: @escaping () -> [String: String] = { [:] },
        timeout: TimeInterval = 30,
        isLoggingEnabled: Bool = false,
        plugins: [Any] = []
    ) {
        self.baseURL = baseURL
        self.globalHeadersProvider = globalHeadersProvider
        self.timeout = timeout
        self.isLoggingEnabled = isLoggingEnabled
        self.plugins = plugins
    }

    /// 默认配置：30s 超时，开启日志（可按需修改）
    public static var `default`: NetworkConfig {
        NetworkConfig(
            baseURL: URL(string: "https://example.com")!,
            globalHeadersProvider: { [:] },
            timeout: 30,
            isLoggingEnabled: true,
            plugins: []
        )
    }
}

/// 统一入口：存放共享配置与工厂方法
public enum Network {
    /// 全局共享配置（应用启动时可改写）
    public static var sharedConfig: NetworkConfig = .default
}



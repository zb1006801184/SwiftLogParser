import Foundation
#if canImport(Moya)
import Moya
import Alamofire

/// 全局请求头插件：在请求发出前统一注入 Headers（仅在可用 Moya 时编译）
private final class GlobalHeadersPlugin: PluginType {
    private let headersProvider: () -> [String: String]

    init(headersProvider: @escaping () -> [String: String]) {
        self.headersProvider = headersProvider
    }

    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var req = request
        let globalHeaders = headersProvider()
        for (key, value) in globalHeaders {
            req.setValue(value, forHTTPHeaderField: key)
        }
        return req
    }
}

/// 基于 Moya 的通用 Provider 封装
public final class NetworkProvider<Target: TargetType> {
    public let provider: MoyaProvider<Target>

    /// 使用外部传入的配置创建 Provider
    public init(config: NetworkConfig = Network.sharedConfig) {
        var plugins: [PluginType] = config.plugins.compactMap { $0 as? PluginType }
        // 全局 Header 插件置前，确保最末覆盖请求头
        plugins.insert(GlobalHeadersPlugin(headersProvider: config.globalHeadersProvider), at: 0)

        if config.isLoggingEnabled {
            // Moya 自带日志插件（按需开启）
            let logger = NetworkLoggerPlugin(
                configuration: .init(
                    logOptions: [.requestBody, .successResponseBody, .errorResponseBody]
                )
            )
            plugins.append(logger)
        }

        let session = Self.makeSession(timeout: config.timeout)
        self.provider = MoyaProvider<Target>(session: session, plugins: plugins)
    }

    /// 统一 Session，配置超时时间、缓存策略等
    private static func makeSession(timeout: TimeInterval) -> Session {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return Session(configuration: configuration)
    }

    /// 发起请求（返回原始 Response）
    @discardableResult
    public func request(_ target: Target) async throws -> Response {
        try await withCheckedThrowingContinuation { continuation in
            provider.request(target) { result in
                switch result {
                case .success(let response):
                    continuation.resume(returning: response)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// 发起请求并解析为指定的 Decodable 类型
    public func requestDecodable<D: Decodable>(
        _ type: D.Type,
        target: Target,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> D {
        let response = try await request(target)
        let filtered = try response.filterSuccessfulStatusCodes()
        return try decoder.decode(D.self, from: filtered.data)
    }
}

#endif


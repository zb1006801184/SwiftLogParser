import Foundation
#if canImport(Moya)
import Moya

/// 统一的 API Target 协议，便于提供默认实现
public protocol APITarget: TargetType {}

public extension APITarget {
    /// 全局统一的基础域名
    var baseURL: URL { Network.sharedConfig.baseURL }
    /// 默认空数据（供单元测试或 Stub 使用）
    var sampleData: Data { Data() }

    /// 默认不追加头（全局头由 `GlobalHeadersPlugin` 统一注入）
    var headers: [String : String]? { nil }
}

#endif



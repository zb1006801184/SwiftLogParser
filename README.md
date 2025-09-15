# SwiftLogParser

## 网络层（Moya）使用说明

示例：定义接口 Target，并用 `NetworkProvider` 发起请求。

```swift
import Moya

enum DemoAPI {
    case user(id: String)
}

extension DemoAPI: APITarget {
    var baseURL: URL { URL(string: "https://api.example.com")! }
    var path: String {
        switch self {
        case .user(let id): return "/users/\(id)"
        }
    }
    var method: Moya.Method { .get }
    var task: Moya.Task { .requestPlain }
}

// 应用启动时配置
Network.sharedConfig = NetworkConfig(
    globalHeadersProvider: { [
        "Accept": "application/json",
        "Authorization": "Bearer YOUR_TOKEN"
    ] },
    timeout: 20,
    isLoggingEnabled: true
)

// 发起请求
let provider = NetworkProvider<DemoAPI>()
Task {
    do {
        struct User: Decodable { let id: String; let name: String }
        let user: User = try await provider.requestDecodable(User.self, target: .user(id: "1"))
        print(user)
    } catch {
        print("request failed: \(error)")
    }
}
```

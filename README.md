

## 项目功能概述

SwiftLogParser 是一款基于 SwiftUI 的 Logan 日志解析与查看工具，支持：

- 解析 Logan 加密日志（AES/CBC 解密 + GZIP 解压，带失败/成功统计）。
- 解析后的日志按行映射为结构化模型并分类显示（错误、告警、信息等）。
- 支持导出解析结果为 JSON 文件并记录解析历史。
- 自定义 AES Key/IV（长度 16），方便适配不同 App 的 Logan 配置。

## 目录与模块说明

- `Core/LogParser/`
  - 解析核心逻辑，包含解密、解压、内容解析、统计等。
  - 关键类：`LoganParserService`（负责解析流程与进度）、`LogType`（日志类型映射）。
- `Core/History/`
  - 解析历史模型、服务与展示视图，便于回顾过去的解析与导出结果。
  - 模型：`ParseHistory`（包含文件大小、条数、是否成功、JSON 路径等）。
- `Core/Settings/`
  - 设置模块，管理 AES Key/IV 的读取与校验，以及与解析服务的对接。
  - 模型：`AppSettings`，并可转换为 `LoganSettings` 提供给解析服务。
- `Core/Shared/`
  - 通用组件（如搜索框、加载视图）与设计规范。
- `Core/Network/`
  - 基于 Moya 的网络封装，包含全局配置、`APITarget` 默认实现与 `NetworkProvider`。
- `Core/Main/`
  - 根视图与导航入口（`MainView`、`ContentView`）。

## 解析流程（业务逻辑）

1. 选择或拖拽 Logan 日志文件，得到文件 `URL`。
2. `LoganParserService.parseLogFile(at:)`：
   - 读取文件数据，初始化进度。
   - 扫描标识符并分块读取加密内容长度与数据。
   - 使用 AES/CBC 解密（Key/IV 来自设置模块）。
   - 使用 GZIP 解压（优先 GzipSwift，失败回退手动解压）。
   - 将解密解压后的文本按行解析为 `LoganLogItem`，并统计成功/失败块数。
   - 导出 JSON 文件，落盘后记录 `ParseHistory`。
3. UI 层显示解析进度与结果列表，支持筛选与查看详情。

## 界面与交互

- `LogParserView`：主解析入口，提供文件选择、进度展示与解析结果列表。
- `LogDetailView`：查看单条日志详情（含类型、时间、线程、内容等）。
- `HistoryView`：解析历史记录列表，支持查看历史导出的 JSON 文件。
- `SettingsContentView`：配置 AES Key/IV，并提供字段校验。

## 使用步骤

1. 启动应用后，进入 `设置` 页面配置 AES Key 与 IV（必须为 16 字符）。
2. 返回解析页，选择 Logan 文件进行解析，等待进度至 100%。
3. 解析完成后，可在列表中浏览日志；如需外部分析，可点击导出后的 JSON 文件。
4. 历史页面可查看过往解析记录（含成功/失败、条数、导出路径等）。

## 构建与运行

- Xcode 15+，macOS 14+（建议与项目配置一致）。
- 打开 `SwiftLogParser.xcodeproj`，选择 `SwiftLogParser` 目标，直接运行。
- 依赖：`Moya`、`Alamofire`、`Gzip`、`ZIPFoundation`（通过 SwiftPM 管理）。

## 配置项（Network 与解析设置）

- 应用启动全局网络配置（示例，中文注释）：
```swift
// App 启动时配置全局网络参数
Network.sharedConfig = NetworkConfig(
    baseURL: URL(string: "https://api.example.com")!, // 基础域名
    globalHeadersProvider: { [
        "Accept": "application/json",            // 默认接收类型
        "Authorization": "Bearer YOUR_TOKEN"     // 按需动态注入
    ] },
    timeout: 20,            // 请求与资源超时（秒）
    isLoggingEnabled: true  // 开启网络日志
)
```

- 解析设置（AES Key/IV）：
  - 在 `设置` 页面修改后会持久化，`LoganParserService` 解析时读取。
  - 必须满足 16 字节长度，否则 `isValid` 失败。

## 多环境与扩展

- 建议在 `App.init()` 中根据编译配置或环境变量切换 `baseURL`。
- `APITarget` 可继续按需扩展 `path`、`method`、`task`、`headers`。
- 日志分类来自 `LogType`，如需新增类型可扩展枚举与图标/颜色映射。

## 常见问题（FAQ）

- 解密失败怎么办？
  - 请确认 AES Key/IV 是否与生成 Logan 的 App 完全一致且为 16 字节。
- 解压失败怎么办？
  - 检查源文件是否为合法的 GZIP；工具已内置回退解压路径与统计信息。
- JSON 导出后在哪里？
  - 解析成功后会在历史记录中显示导出的 JSON 文件路径，可直接打开。

## 许可证

本项目遵循 MIT 许可证，详见 `LICENSE` 文件。

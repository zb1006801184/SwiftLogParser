

## SwiftLogParser

一款基于 SwiftUI 的 Logan 日志解析与查看工具。

## 环境要求

- macOS 14 或更高版本
- Xcode 15 或更高版本
- 依赖通过 Swift Package Manager 管理

## 快速开始

1. 打开 `SwiftLogParser.xcodeproj`。
2. 选择 `SwiftLogParser` 目标并运行。
3. 首次启动先在「设置」中配置 AES Key 与 IV（必须为 16 字符）。
4. 回到解析页，选择 Logan 文件，等待进度至 100%。

## 核心功能

- 解析 Logan 加密日志（AES/CBC 解密 + GZIP 解压，含成功/失败统计）。
- 将日志行映射为结构化模型，按类型分类（错误、告警、信息等）。
- 导出解析结果为 JSON，并自动记录解析历史。
- 自定义 AES Key/IV（长度 16），适配不同 App 的 Logan 配置。

## 目录结构（概要）

- `Core/LogParser/`
  - 解密、解压、内容解析与统计。
  - 关键类型：`LoganParserService`、`LogType`。
- `Core/History/`
  - 解析历史模型、服务与视图（`ParseHistory` 等）。
- `Core/Settings/`
  - AES Key/IV 的读取、校验与持久化；对接解析服务。
- `Core/Shared/`
  - 通用组件与设计系统（如搜索框、加载视图）。
- `Core/Network/`
  - 基于 Moya 的网络封装（`APITarget`、`NetworkProvider` 等）。
- `Core/Main/`
  - 根视图与导航入口（`MainView`、`ContentView`）。

## 使用指南

1. 进入「设置」配置 AES Key 与 IV（均需 16 字符）。
2. 在解析页选择或拖拽 Logan 文件。
3. 查看解析进度与结果列表；可按类型筛选并查看详情。
4. 如需外部分析，使用导出按钮生成 JSON 并在历史中查看路径。

## 构建与运行

- 打开 `SwiftLogParser.xcodeproj`，选择 `SwiftLogParser` 目标运行。
- 依赖：`Moya`、`Alamofire`、`Gzip`、`ZIPFoundation`（SwiftPM 管理）。
- 若使用脚本构建，可参考根目录 `build.sh`（按需调整 Xcode 版本）。

## 配置说明

- 网络：在应用启动时配置全局网络参数（可选）。
```swift
// App 启动时配置全局网络参数
Network.sharedConfig = NetworkConfig(
    baseURL: URL(string: "https://api.example.com")!,
    globalHeadersProvider: { [
        "Accept": "application/json",
        "Authorization": "Bearer YOUR_TOKEN"
    ] },
    timeout: 20,
    isLoggingEnabled: true
)
```

- 解析设置（AES Key/IV）：
  - 在「设置」页面修改后会持久化，解析时自动读取。
  - 必须均为 16 字节长度，否则校验失败。

## 解析流程（概览）

1. 选择或拖拽 Logan 日志文件，得到文件 `URL`。
2. `LoganParserService.parseLogFile(at:)` 执行：
   - 读取数据并初始化进度。
   - 扫描标识符，分块读取密文长度与数据。
   - 使用 AES/CBC 解密（Key/IV 来源于设置）。
   - 使用 GZIP 解压（失败自动回退）。
   - 解析为结构化模型，统计成功/失败块数并导出 JSON。
3. UI 展示进度与结果列表，支持筛选、详情与历史查看。

## 多环境与扩展建议

- 在 `App.init()` 或构建配置中切换 `baseURL`。
- `APITarget` 可扩展 `path`、`method`、`task`、`headers`。
- 新增日志类型时扩展 `LogType` 及其图标/颜色映射。

## 常见问题（FAQ）

- 解密失败怎么办？
  - 确认 AES Key/IV 与产生日志的 App 完全一致，且均为 16 字节。
- 解压失败怎么办？
  - 检查源文件是否为合法 GZIP；本工具存在回退解压与统计提示。
- JSON 导出文件在哪里？
  - 历史记录中会显示导出的 JSON 路径，可直接打开查看。

## 许可证

本项目遵循 MIT 许可证，详见 `LICENSE` 文件。

## 致谢

- Logan 日志格式及相关生态。
- 社区提供的 Swift/SwiftUI 与压缩/加密库。

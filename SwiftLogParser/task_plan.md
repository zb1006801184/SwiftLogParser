# Logan 日志解析工具 - SwiftUI 重写任务文档

## 项目概述

基于现有 Flutter 桌面端应用 项目路径（～/work/loggeranalysis），使用 SwiftUI 重新开发 Logan 日志解析工具。该工具用于解析和查看美团 Logan 日志框架生成的加密日志文件。

## 核心功能需求

### 1. 日志文件解析功能
- **文件选择**：支持通过文件选择器选择 Logan 加密日志文件
- **AES 解密**：使用 AES/CBC/NoPadding 模式解密日志内容
- **GZIP 解压缩**：对解密后的数据进行 GZIP 解压缩
- **JSON 解析**：将解压缩后的内容解析为结构化的日志条目
- **错误处理**：完善的错误捕获和用户友好的错误提示

### 2. 日志查看和管理
- **日志列表**：以列表形式展示解析后的日志条目，最新日志显示在顶部
- **日志详情**：点击日志条目查看详细信息（时间、类型、内容、线程信息等）
- **智能搜索**：支持按内容、时间、线程名称进行关键词搜索
- **类型筛选**：支持按日志类型筛选（调试、信息、错误、警告、严重错误、网络请求、性能指标）
- **内容复制**：长按日志详情可复制内容到剪贴板

### 3. 数据持久化
- **解析历史**：记录所有解析过的文件历史，包括文件路径、解析时间、文件大小、日志条数
- **JSON 导出**：自动生成 JSON 格式的解析结果文件，保存至用户文档目录
- **状态恢复**：应用重启后恢复上次的工作状态
- **历史管理**：支持查看、重新打开、删除历史记录

### 4. 设置管理
- **AES 密钥配置**：支持自定义 AES 密钥和向量
- **默认密钥**：提供默认密钥 "0123456789012345"
- **密钥重置**：支持重置为默认密钥
- **设置持久化**：使用 UserDefaults 保存用户设置

## 技术架构要求

### 1. 开发框架
- **UI 框架**：SwiftUI
- **最低系统版本**：macOS 12.0+
- **开发语言**：Swift 5.7+
- **架构模式**：MVVM + Combine

### 2. 核心依赖库
- **加密解密**：CommonCrypto（AES/CBC/NoPadding，手动移除 PKCS7）
- **文件压缩**：Compression（GZIP 解压缩）
- **JSON 处理**：Codable
- **文件操作**：Foundation
- **状态管理**：Combine + @StateObject/@ObservedObject

### 4. SwiftUI 业务文件结构（其余保持 Xcode 默认）

```
LoganParserSwiftUI/
├── Core/                               # 业务核心（纯逻辑与工具）
│   ├── Models/                         # 数据模型
│   │   ├── logan_log_item.swift
│   │   ├── parse_history.swift
│   │   └── app_settings.swift
│   ├── Services/                       # 服务层（无 UI 依赖）
│   │   ├── logan_parser_service.swift  # Logan 解析（AES/CBC + GZIP + JSON）
│   │   ├── settings_service.swift      # UserDefaults 读写
│   │   └── file_manager_service.swift  # 路径/导出/文件操作
│   ├── Utils/                          # 工具扩展
│   │   ├── date+ext.swift
│   │   ├── data+compression.swift
│   │   └── logger.swift
│   └── Constants/
│       └── logan_constants.swift
├── Features/                           # 业务功能（UI + ViewModel）
│   ├── Home/
│   │   ├── home_view.swift
│   │   └── home_view_model.swift
│   ├── LogDecode/
│   │   ├── log_decode_view.swift
│   │   ├── log_decode_view_model.swift
│   │   └── widgets/
│   │       ├── search_bar.swift
│   │       ├── filter_picker.swift
│   │       ├── log_item_row.swift
│   │       └── log_detail_panel.swift
│   ├── History/
│   │   ├── parse_history_view.swift
│   │   ├── parse_history_view_model.swift
│   │   └── widgets/
│   │       └── parse_history_row.swift
│   └── Settings/
│       ├── settings_view.swift
│       ├── settings_view_model.swift
│       └── widgets/
│           └── key_field.swift
├── Shared/                             # 共享 UI 组件
│   ├── Components/
│   │   ├── sidebar_menu.swift
│   │   ├── floating_add_button.swift
│   │   ├── empty_state_view.swift
│   │   ├── loading_view.swift
│   │   └── error_view.swift
│   └── Theme/
│       ├── colors.swift
│       ├── typography.swift
│       └── spacing.swift
└── Bridging/                           # CommonCrypto 桥接
    └── Bridging-Header.h               # #import <CommonCrypto/CommonCrypto.h>
```

说明：除上述业务目录外，其余工程结构（如 App 入口、Assets、Info 等）保持 Xcode 默认生成，不做自定义约束。

### 3. 数据模型

#### LoganLogItem（日志条目）
```swift
struct LoganLogItem: Codable, Identifiable {
    let id = UUID()
    let content: String?        // 日志内容 (c)
    let flag: String?          // 日志类型标识 (f)
    let logTime: String?       // 日志时间 (l)
    let threadName: String?    // 线程名称 (n)
    let threadId: String?      // 线程ID (i)
    let isMainThread: String?  // 是否主线程 (m)
}
```

#### ParseHistory（解析历史）
```swift
struct ParseHistory: Codable, Identifiable {
    let id = UUID()
    let filePath: String       // 文件路径
    let fileName: String       // 文件名
    let parseTime: Date        // 解析时间
    let fileSize: Int          // 文件大小
    let logCount: Int          // 日志条数
    let isSuccess: Bool        // 解析是否成功
    let errorMessage: String?  // 错误信息
}
```

#### AppSettings（应用设置）
```swift
struct AppSettings: Codable {
    var aesKey: String         // AES 密钥
    var aesIv: String          // AES 向量
}
```

## UI 设计要求

### 1. 整体布局
- **侧边菜单**：左侧固定宽度 200px 的导航菜单
- **主内容区**：右侧自适应宽度的内容展示区域
- **响应式设计**：支持窗口大小调整
- **深色主题**：现代化的深色主题设计

### 2. 页面结构

#### 主页面（HomeView）
- 使用 NavigationSplitView 或自定义布局
- 左侧：SidebarView（导航菜单）
- 右侧：根据选中菜单项显示不同页面

#### 日志解析页面（LogDecodeView）
- **顶部工具栏**：搜索框 + 筛选下拉菜单
- **主内容区**：左右分栏布局
  - 左侧：日志列表（LogListView）
  - 右侧：日志详情（LogDetailView）
- **浮动按钮**：右下角的文件选择按钮

#### 解析历史页面（ParseHistoryView）
- **历史列表**：显示所有解析历史记录
- **操作按钮**：重新打开、删除、在 Finder 中显示
- **空状态**：无历史记录时的提示界面

#### 设置页面（SettingsView）
- **密钥配置**：AES 密钥和向量的输入框
- **重置按钮**：恢复默认设置
- **保存按钮**：保存当前设置

### 3. 组件设计

#### 通用组件
- **LoadingView**：加载状态指示器
- **EmptyStateView**：空状态提示
- **ErrorView**：错误状态显示
- **SearchBar**：搜索输入框
- **FilterPicker**：筛选下拉选择器

#### 日志相关组件
- **LogItemView**：日志条目卡片
- **LogDetailView**：日志详情面板
- **LogListView**：日志列表容器

#### 菜单组件
- **SidebarView**：侧边导航菜单
- **MenuItemView**：菜单项组件

## 核心业务逻辑

### 1. Logan 解析算法详细流程

#### 1.1 文件结构解析
Logan 日志文件采用二进制格式，包含多个加密数据块：

```
文件结构：
[标识符: 1字节] [长度: 4字节] [加密数据: N字节] [标识符: 1字节] [长度: 4字节] [加密数据: M字节] ...
```

#### 1.2 详细解析步骤

**步骤 1：文件读取**
```swift
// 读取整个文件为字节数组
let fileData = try Data(contentsOf: fileURL)
var offset = 0
var decryptedContent = ""
```

**步骤 2：循环解析数据块**
```swift
while offset < fileData.count {
    // 2.1 查找加密内容开始标识符
    guard offset < fileData.count else { break }
    let marker = fileData[offset]
    
    if marker != 0x01 {  // 0x01 是加密内容开始标识符
        offset += 1
        continue
    }
    
    offset += 1  // 跳过标识符
    
    // 2.2 读取加密内容长度（4字节，大端序）
    guard offset + 4 <= fileData.count else { break }
    let lengthBytes = fileData.subdata(in: offset..<offset+4)
    let encryptedLength = lengthBytes.withUnsafeBytes { bytes in
        bytes.load(as: UInt32.self).bigEndian
    }
    offset += 4
    
    // 2.3 提取加密数据块
    guard offset + Int(encryptedLength) <= fileData.count else { break }
    let encryptedData = fileData.subdata(in: offset..<offset+Int(encryptedLength))
    offset += Int(encryptedLength)
    
    // 2.4 解密数据块
    let decryptedData = try decryptAES(data: encryptedData)
    
    // 2.5 GZIP 解压缩
    let decompressedData = try decompressGzip(data: decryptedData)
    
    // 2.6 转换为字符串
    if let content = String(data: decompressedData, encoding: .utf8) {
        decryptedContent += content
    }
}
```

**步骤 3：AES 解密实现**
```swift
func decryptAES(data: Data) throws -> Data {
    // 3.1 获取密钥和向量
    let keyString = settings.aesKey  // 默认: "0123456789012345"
    let ivString = settings.aesIv    // 默认: "0123456789012345"
    
    let key = keyString.data(using: .utf8)!
    let iv = ivString.data(using: .utf8)!
    
    // 3.2 确保数据长度是16的倍数（AES块大小）
    var dataToDecrypt = data
    if dataToDecrypt.count % 16 != 0 {
        let paddedLength = ((dataToDecrypt.count / 16) + 1) * 16
        var paddedData = Data(count: paddedLength)
        paddedData.replaceSubrange(0..<dataToDecrypt.count, with: dataToDecrypt)
        dataToDecrypt = paddedData
    }
    
    // 3.3 使用 CryptoKit 进行 AES/CBC 解密
    // 注意：Logan 使用 AES/CBC/NoPadding 模式，不是 GCM 模式
    let keyData = SymmetricKey(data: key)
    let ivData = iv
    
    // 使用 CommonCrypto 进行 AES/CBC 解密（CryptoKit 不直接支持 CBC 模式）
    let decryptedData = try decryptAESCBC(
        data: dataToDecrypt,
        key: key,
        iv: ivData
    )
    
    // 3.4 移除 PKCS7 填充
    return removePKCS7Padding(data: decryptedData)
}

// AES/CBC 解密实现（使用 CommonCrypto）
import CommonCrypto

func decryptAESCBC(data: Data, key: Data, iv: Data) throws -> Data {
    let cryptLength = size_t(data.count + kCCBlockSizeAES128)
    var cryptData = Data(count: cryptLength)
    
    let keyLength = size_t(kCCKeySizeAES128)
    let operation: CCOperation = UInt32(kCCDecrypt)
    let algorithm: CCAlgorithm = UInt32(kCCAlgorithmAES128)
    // Logan 原始实现使用 NoPadding（按块对齐），Flutter 侧已手动补齐并在解密后自行移除 PKCS7
    // 这里保持与现有实现一致，使用 NoPadding，后续按需移除 PKCS7
    let options: CCOptions = 0 // kCCOptionPKCS7Padding = 0x0001，NoPadding 则为 0
    
    var numBytesDecrypted: size_t = 0
    
    let cryptStatus = cryptData.withUnsafeMutableBytes { cryptBytes in
        data.withUnsafeBytes { dataBytes in
            iv.withUnsafeBytes { ivBytes in
                key.withUnsafeBytes { keyBytes in
                    CCCrypt(operation,
                           algorithm,
                           options,
                           keyBytes.bindMemory(to: UInt8.self).baseAddress, keyLength,
                           ivBytes.bindMemory(to: UInt8.self).baseAddress,
                           dataBytes.bindMemory(to: UInt8.self).baseAddress, data.count,
                           cryptBytes.bindMemory(to: UInt8.self).baseAddress, cryptLength,
                           &numBytesDecrypted)
                }
            }
        }
    }
    
    guard UInt32(cryptStatus) == UInt32(kCCSuccess) else {
        throw LoganParseError.decryptionFailed
    }
    
    cryptData.removeSubrange(numBytesDecrypted..<cryptData.count)
    return cryptData
}

// PKCS7 填充移除
func removePKCS7Padding(data: Data) -> Data {
    guard !data.isEmpty else { return data }
    
    let paddingLength = data.last!
    guard paddingLength > 0 && paddingLength <= 16 && paddingLength <= data.count else {
        return data
    }
    
    // 验证填充是否正确
    let paddingStart = data.count - Int(paddingLength)
    for i in paddingStart..<data.count {
        if data[i] != paddingLength {
            return data  // 填充不正确，返回原数据
        }
    }
    
    return data.subdata(in: 0..<paddingStart)
}
```

**步骤 4：GZIP 解压缩实现**
```swift
import Compression

func decompressGzip(data: Data) throws -> Data {
    // 兼容 gzip/zlib 两种容器头：Logan 通常使用 gzip
    // Compression 使用 zlib；这里优先尝试 gzip，失败再回退 zlib
    let source = data as NSData
    
    // 优先尝试 gzip (COMPRESSION_ZLIB 与 gzip 头兼容，但遇到原始 deflate 可能失败)
    if let decompressed = source.decompressed(using: COMPRESSION_ZLIB) {
        return decompressed as Data
    }
    // 回退：直接调用低层 API 解压（可能是 raw deflate）
    let bufferSize = max(data.count * 4, 64 * 1024)
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    defer { buffer.deallocate() }
    let decompressedSize = compression_decode_buffer(
        buffer, bufferSize,
        data.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! },
        data.count,
        nil,
        COMPRESSION_ZLIB
    )
    guard decompressedSize > 0 else { throw LoganParseError.decompressionFailed }
    return Data(bytes: buffer, count: decompressedSize)
}
```

**步骤 5：JSON 内容解析**
```swift
func parseLogContent(_ content: String) -> [LoganLogItem] {
    var logItems: [LoganLogItem] = []
    let lines = content.components(separatedBy: .newlines)
    
    for line in lines {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedLine.isEmpty else { continue }
        
        do {
            // 尝试解析为 JSON
            let jsonData = try JSONSerialization.jsonObject(with: trimmedLine.data(using: .utf8)!)
            
            if let jsonDict = jsonData as? [String: Any] {
                let logItem = LoganLogItem(
                    content: jsonDict["c"] as? String ?? "",
                    flag: jsonDict["f"] as? String ?? "3",
                    logTime: formatLogTime(jsonDict["l"]),
                    threadName: jsonDict["n"] as? String ?? "unknown",
                    threadId: jsonDict["i"] as? String ?? "0",
                    isMainThread: jsonDict["m"] as? String ?? "false"
                )
                logItems.append(logItem)
            }
        } catch {
            // 如果不是 JSON 格式，创建简单日志项
            let logItem = LoganLogItem(
                content: trimmedLine,
                flag: "3",
                logTime: Date().iso8601String,
                threadName: "unknown",
                threadId: "0",
                isMainThread: "false"
            )
            logItems.append(logItem)
        }
    }
    
    return logItems
}

// 时间格式化
func formatLogTime(_ timeValue: Any?) -> String {
    guard let timeValue = timeValue else {
        return Date().iso8601String
    }
    
    var timestamp: Int64 = 0
    
    if let stringValue = timeValue as? String {
        timestamp = Int64(stringValue) ?? 0
    } else if let numberValue = timeValue as? NSNumber {
        timestamp = numberValue.int64Value
    }
    
    // Logan 使用毫秒时间戳
    let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
    return date.iso8601String
}
```

#### 1.3 错误处理策略
```swift
enum LoganParseError: Error {
    case fileNotFound
    case invalidFileFormat
    case decryptionFailed
    case decompressionFailed
    case jsonParseFailed
    case emptyResult
}

// 解析过程中的错误处理
do {
    let logItems = try parseLoganFile(at: fileURL)
    // 处理成功结果
} catch LoganParseError.decryptionFailed {
    // 解密失败，可能是密钥错误
} catch LoganParseError.decompressionFailed {
    // 解压缩失败，可能是数据损坏
} catch {
    // 其他错误
}
```

### 2. 关键常量和配置

#### 2.1 Logan 文件格式常量
```swift
struct LoganConstants {
    // 加密内容开始标识符
    static let encryptContentStart: UInt8 = 0x01
    
    // 默认 AES 密钥和向量
    static let defaultAesKey = "0123456789012345"
    static let defaultAesIv = "0123456789012345"
    
    // AES 块大小
    static let aesBlockSize = 16
    
    // JSON 字段映射
    static let jsonFields = (
        content: "c",      // 日志内容
        flag: "f",         // 日志类型标识
        logTime: "l",      // 日志时间
        threadName: "n",   // 线程名称
        threadId: "i",     // 线程ID
        isMainThread: "m"  // 是否主线程
    )
}
```

#### 2.2 日志类型映射
```swift
let logTypeMapping: [String: String] = [
    "2": "调试信息",
    "3": "信息/埋点", 
    "4": "错误信息",
    "5": "警告信息",
    "6": "严重错误",
    "7": "网络请求",
    "8": "性能指标"
]

// 日志类型颜色映射（用于 UI 显示）
let logTypeColors: [String: Color] = [
    "2": .blue,      // 调试信息 - 蓝色
    "3": .green,     // 信息/埋点 - 绿色
    "4": .red,       // 错误信息 - 红色
    "5": .orange,    // 警告信息 - 橙色
    "6": .purple,    // 严重错误 - 紫色
    "7": .cyan,      // 网络请求 - 青色
    "8": .yellow     // 性能指标 - 黄色
]
```

### 3. 完整的数据模型定义

#### 3.1 LoganLogItem 详细定义
```swift
struct LoganLogItem: Codable, Identifiable, Equatable {
    let id = UUID()
    
    // 日志内容 (JSON 字段: "c")
    let content: String?
    
    // 日志类型标识 (JSON 字段: "f")
    // 2:调试, 3:信息/埋点, 4:错误, 5:警告, 6:严重错误, 7:网络请求, 8:性能指标
    let flag: String?
    
    // 日志时间 (JSON 字段: "l") - 毫秒时间戳
    let logTime: String?
    
    // 线程名称 (JSON 字段: "n")
    let threadName: String?
    
    // 线程ID (JSON 字段: "i")
    let threadId: String?
    
    // 是否主线程 (JSON 字段: "m")
    let isMainThread: String?
    
    // 计算属性：格式化的日志时间
    var formattedLogTime: String {
        guard let logTime = logTime else { return "未知时间" }
        
        if let timestamp = Int64(logTime) {
            let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            return formatter.string(from: date)
        }
        
        return logTime
    }
    
    // 计算属性：日志类型描述
    var logTypeDescription: String {
        return logTypeMapping[flag ?? "3"] ?? "其他"
    }
    
    // 计算属性：日志类型颜色
    var logTypeColor: Color {
        return logTypeColors[flag ?? "3"] ?? .gray
    }
    
    // 搜索匹配方法
    func containsKeyword(_ keyword: String) -> Bool {
        guard !keyword.isEmpty else { return true }
        
        let lowerKeyword = keyword.lowercased()
        return (content?.lowercased().contains(lowerKeyword) ?? false) ||
               (logTime?.lowercased().contains(lowerKeyword) ?? false) ||
               (threadName?.lowercased().contains(lowerKeyword) ?? false) ||
               (logTypeDescription.lowercased().contains(lowerKeyword))
    }
    
    // 筛选匹配方法
    func matchesFilter(_ filterType: String) -> Bool {
        guard !filterType.isEmpty && filterType != "全部日志" else { return true }
        return flag == filterType
    }
    
    // 自定义编码键
    enum CodingKeys: String, CodingKey {
        case content = "c"
        case flag = "f"
        case logTime = "l"
        case threadName = "n"
        case threadId = "i"
        case isMainThread = "m"
    }
}
```

#### 3.2 ParseHistory 详细定义
```swift
struct ParseHistory: Codable, Identifiable, Equatable {
    let id = UUID()
    
    // 文件路径
    let filePath: String
    
    // 文件名
    let fileName: String
    
    // 解析时间
    let parseTime: Date
    
    // 文件大小（字节）
    let fileSize: Int
    
    // 解析出的日志条数
    let logCount: Int
    
    // 解析是否成功
    let isSuccess: Bool
    
    // 错误信息（如果解析失败）
    let errorMessage: String?
    
    // 计算属性：格式化的文件大小
    var fileSizeFormatted: String {
        if fileSize < 1024 {
            return "\(fileSize)B"
        } else if fileSize < 1024 * 1024 {
            return String(format: "%.1fKB", Double(fileSize) / 1024.0)
        } else {
            return String(format: "%.1fMB", Double(fileSize) / (1024.0 * 1024.0))
        }
    }
    
    // 计算属性：格式化的解析时间
    var parseTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: parseTime)
    }
    
    // 计算属性：状态描述
    var statusDescription: String {
        return isSuccess ? "解析成功" : "解析失败"
    }
    
    // 计算属性：状态颜色
    var statusColor: Color {
        return isSuccess ? .green : .red
    }
}
```

#### 3.3 AppSettings 详细定义
```swift
struct AppSettings: Codable {
    // AES 密钥
    var aesKey: String
    
    // AES 向量
    var aesIv: String
    
    // 是否使用深色主题
    var isDarkMode: Bool
    
    // 默认设置
    static let `default` = AppSettings(
        aesKey: LoganConstants.defaultAesKey,
        aesIv: LoganConstants.defaultAesIv,
        isDarkMode: true
    )
    
    // 检查是否使用默认密钥
    var isUsingDefaultKeys: Bool {
        return aesKey == LoganConstants.defaultAesKey && 
               aesIv == LoganConstants.defaultAesIv
    }
    
    // 重置为默认设置
    mutating func resetToDefault() {
        aesKey = LoganConstants.defaultAesKey
        aesIv = LoganConstants.defaultAesIv
    }
    
    // 验证密钥格式
    func validateKeys() -> (isValid: Bool, message: String) {
        if aesKey.count != 16 {
            return (false, "AES 密钥长度必须为 16 字节")
        }
        
        if aesIv.count != 16 {
            return (false, "AES 向量长度必须为 16 字节")
        }
        
        return (true, "密钥格式正确")
    }
}
```

### 4. 完整的解析服务类示例

```swift
import Foundation
import CommonCrypto
import Compression

class LoganParserService: ObservableObject {
    @Published var isParsing = false
    @Published var parseProgress: Double = 0.0
    
    private let settings: AppSettings
    
    init(settings: AppSettings) {
        self.settings = settings
    }
    
    // 主解析方法
    func parseLogFile(at url: URL) async throws -> [LoganLogItem] {
        await MainActor.run { isParsing = true }
        defer { Task { @MainActor in isParsing = false } }
        
        // 读取文件数据
        let fileData = try Data(contentsOf: url)
        await updateProgress(0.1)
        
        // 解析 Logan 文件
        let decryptedContent = try await parseLoganFile(data: fileData)
        await updateProgress(0.7)
        
        // 解析日志内容
        let logItems = parseLogContent(decryptedContent)
        await updateProgress(0.9)
        
        // 生成 JSON 文件
        try await generateJsonFile(logItems: logItems, originalFileName: url.lastPathComponent)
        await updateProgress(1.0)
        
        return logItems
    }
    
    // 解析 Logan 文件格式
    private func parseLoganFile(data: Data) async throws -> String {
        var offset = 0
        var decryptedContent = ""
        let totalBytes = data.count
        
        while offset < data.count {
            // 更新进度
            let progress = 0.1 + (Double(offset) / Double(totalBytes)) * 0.6
            await updateProgress(progress)
            
            // 查找加密内容开始标识符
            guard offset < data.count else { break }
            let marker = data[offset]
            
            if marker != LoganConstants.encryptContentStart {
                offset += 1
                continue
            }
            
            offset += 1  // 跳过标识符
            
            // 读取加密内容长度（4字节，大端序）
            guard offset + 4 <= data.count else { break }
            let lengthBytes = data.subdata(in: offset..<offset+4)
            let encryptedLength = lengthBytes.withUnsafeBytes { bytes in
                bytes.load(as: UInt32.self).bigEndian
            }
            offset += 4
            
            // 提取加密数据块
            guard offset + Int(encryptedLength) <= data.count else { break }
            let encryptedData = data.subdata(in: offset..<offset+Int(encryptedLength))
            offset += Int(encryptedLength)
            
            do {
                // 解密数据块
                let decryptedData = try decryptAES(data: encryptedData)
                
                // GZIP 解压缩
                let decompressedData = try decompressGzip(data: decryptedData)
                
                // 转换为字符串
                if let content = String(data: decompressedData, encoding: .utf8) {
                    decryptedContent += content
                }
            } catch {
                // 单个块解析失败，继续处理下一个块
                print("处理加密块失败: \(error)")
                continue
            }
        }
        
        return decryptedContent
    }
    
    // AES 解密
    private func decryptAES(data: Data) throws -> Data {
        let keyString = settings.aesKey
        let ivString = settings.aesIv
        
        let key = keyString.data(using: .utf8)!
        let iv = ivString.data(using: .utf8)!
        
        // 确保数据长度是16的倍数
        var dataToDecrypt = data
        if dataToDecrypt.count % 16 != 0 {
            let paddedLength = ((dataToDecrypt.count / 16) + 1) * 16
            var paddedData = Data(count: paddedLength)
            paddedData.replaceSubrange(0..<dataToDecrypt.count, with: dataToDecrypt)
            dataToDecrypt = paddedData
        }
        
        // 使用 CommonCrypto 进行 AES/CBC 解密
        let decryptedData = try decryptAESCBC(data: dataToDecrypt, key: key, iv: iv)
        
        // 移除 PKCS7 填充
        return removePKCS7Padding(data: decryptedData)
    }
    
    // GZIP 解压缩
    private func decompressGzip(data: Data) throws -> Data {
        let bufferSize = data.count * 4
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        
        let decompressedSize = compression_decode_buffer(
            buffer, bufferSize,
            data.withUnsafeBytes { $0.bindMemory(to: UInt8.self).baseAddress! },
            data.count,
            nil,
            COMPRESSION_ZLIB
        )
        
        guard decompressedSize > 0 else {
            throw LoganParseError.decompressionFailed
        }
        
        return Data(bytes: buffer, count: decompressedSize)
    }
    
    // 解析日志内容
    private func parseLogContent(_ content: String) -> [LoganLogItem] {
        var logItems: [LoganLogItem] = []
        let lines = content.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty else { continue }
            
            do {
                let jsonData = try JSONSerialization.jsonObject(with: trimmedLine.data(using: .utf8)!)
                
                if let jsonDict = jsonData as? [String: Any] {
                    let logItem = LoganLogItem(
                        content: jsonDict["c"] as? String ?? "",
                        flag: jsonDict["f"] as? String ?? "3",
                        logTime: formatLogTime(jsonDict["l"]),
                        threadName: jsonDict["n"] as? String ?? "unknown",
                        threadId: jsonDict["i"] as? String ?? "0",
                        isMainThread: jsonDict["m"] as? String ?? "false"
                    )
                    logItems.append(logItem)
                }
            } catch {
                // 非 JSON 格式，创建简单日志项
                let logItem = LoganLogItem(
                    content: trimmedLine,
                    flag: "3",
                    logTime: Date().iso8601String,
                    threadName: "unknown",
                    threadId: "0",
                    isMainThread: "false"
                )
                logItems.append(logItem)
            }
        }
        
        return logItems
    }
    
    // 时间格式化
    private func formatLogTime(_ timeValue: Any?) -> String {
        guard let timeValue = timeValue else {
            return Date().iso8601String
        }
        
        var timestamp: Int64 = 0
        
        if let stringValue = timeValue as? String {
            timestamp = Int64(stringValue) ?? 0
        } else if let numberValue = timeValue as? NSNumber {
            timestamp = numberValue.int64Value
        }
        
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
        return date.iso8601String
    }
    
    // 生成 JSON 文件
    private func generateJsonFile(logItems: [LoganLogItem], originalFileName: String) async throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let logDirectory = documentsPath.appendingPathComponent("log")
        
        // 确保目录存在
        try FileManager.default.createDirectory(at: logDirectory, withIntermediateDirectories: true)
        
        // 生成文件名
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let nameWithoutExtension = (originalFileName as NSString).deletingPathExtension
        let fileName = "\(nameWithoutExtension)_parsed_\(timestamp).json"
        let fileURL = logDirectory.appendingPathComponent(fileName)
        
        // 编码为 JSON
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(logItems)
        
        // 写入文件
        try jsonData.write(to: fileURL)
        
        print("JSON 文件已生成: \(fileURL.path)")
    }
    
    // 更新进度
    @MainActor
    private func updateProgress(_ progress: Double) {
        parseProgress = progress
    }
}

// 扩展 Date 以支持 ISO8601 字符串
extension Date {
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}
```

### 5. 文件存储路径
- **JSON 导出路径**：`~/Documents/log/原文件名_parsed_时间戳.json`
- **历史记录存储**：UserDefaults 或 Core Data
- **设置存储**：UserDefaults

## 状态管理

### 1. 应用状态
```swift
enum AppState {
    case idle                    // 空闲状态
    case loading                 // 加载中
    case success([LoganLogItem]) // 解析成功
    case error(String)           // 解析失败
    case searchEmpty             // 搜索无结果
}
```

### 2. 数据流
- 使用 Combine 进行响应式编程
- @StateObject 管理页面状态
- @ObservedObject 监听数据变化
- @Published 属性驱动 UI 更新

## 性能优化

### 1. 内存管理
- 大文件分块处理，避免内存溢出
- 及时释放不需要的数据
- 使用弱引用避免循环引用

### 2. UI 性能
- 使用 LazyVStack 优化长列表性能
- 实现虚拟化滚动
- 避免不必要的视图重建

### 3. 文件处理
- 异步处理大文件解析
- 显示解析进度
- 支持取消操作

## 错误处理

### 1. 文件相关错误
- 文件不存在
- 文件格式不正确
- 文件权限问题
- 磁盘空间不足

### 2. 解析相关错误
- 解密失败
- 解压缩失败
- JSON 解析错误
- 数据格式异常

### 3. 用户友好提示
- 清晰的错误消息
- 操作建议
- 重试机制

## 测试要求

### 1. 单元测试
- 数据模型测试
- 解析算法测试
- 工具类测试

### 2. 集成测试
- 文件解析流程测试
- UI 交互测试
- 数据持久化测试

### 3. 性能测试
- 大文件解析性能
- 内存使用情况
- UI 响应性能

## 部署要求

### 1. 应用打包
- 使用 Xcode 打包为 .app 文件
- 支持代码签名
- 生成 DMG 安装包

### 2. 系统兼容性
- 最低支持 macOS 12.0
- 支持 Intel 和 Apple Silicon
- 适配不同屏幕尺寸

### 3. 发布准备
- 应用图标设计
- 应用描述和截图
- 版本号管理
- 更新机制

## 开发里程碑

### 阶段一：基础架构（1-2周）
- [ ] 项目初始化和基础架构搭建
- [ ] 数据模型定义
- [ ] 基础 UI 框架
- [ ] 导航和路由

### 阶段二：核心功能（2-3周）
- [ ] Logan 解析算法实现
- [ ] 文件选择和解析功能
- [ ] 日志列表和详情展示
- [ ] 搜索和筛选功能

### 阶段三：高级功能（1-2周）
- [ ] 解析历史管理
- [ ] JSON 导出功能
- [ ] 设置页面
- [ ] 数据持久化

### 阶段四：优化和测试（1周）
- [ ] 性能优化
- [ ] 错误处理完善
- [ ] UI 细节优化
- [ ] 测试和调试

### 阶段五：打包发布（0.5周）
- [ ] 应用打包
- [ ] 安装包制作
- [ ] 文档完善
- [ ] 发布准备

## 注意事项

1. **安全性**：确保密钥存储安全，不在代码中硬编码敏感信息
2. **用户体验**：提供清晰的操作反馈，避免用户困惑
3. **错误恢复**：提供完善的错误恢复机制
4. **性能考虑**：大文件处理时提供进度指示和取消功能
5. **兼容性**：确保在不同 macOS 版本上的兼容性
6. **可维护性**：代码结构清晰，注释完整，便于后续维护

## 技术参考

- [SwiftUI 官方文档](https://developer.apple.com/documentation/swiftui)
- [Combine 框架文档](https://developer.apple.com/documentation/combine)
- [CryptoKit 文档](https://developer.apple.com/documentation/cryptokit)
- [Logan 日志框架](https://github.com/Meituan-Dianping/Logan)

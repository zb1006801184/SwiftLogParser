//
//  logan_parser_service.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/8.
//

import Foundation
import Gzip
import Combine
import CommonCrypto
import Compression
import ZIPFoundation

// MARK: - Logan 常量定义
struct LoganConstants {
    /// Logan 加密内容开始标识符
    static let encryptContentStart: UInt8 = 0x01
    /// 默认 AES 密钥
    static let defaultAesKey = "0123456789012345"
    /// 默认 AES IV
    static let defaultAesIv = "0123456789012345"
}

// MARK: - Logan 解析错误定义
enum LoganParseError: Error, LocalizedError {
    case emptyResult
    case decryptionFailed
    case decompressionFailed
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .emptyResult:
            return "解析结果为空"
        case .decryptionFailed:
            return "AES 解密失败"
        case .decompressionFailed:
            return "GZIP 解压缩失败"
        case .invalidData:
            return "无效数据"
        }
    }
}

// MARK: - 解压统计信息结构
struct DecompressionStats {
    var totalBlocks: Int = 0            // 总加密块数（用作统计基准）
    var successfulBlocks: Int = 0       // 成功解压的加密块数
    var failedBlocks: Int = 0          // 解压失败的加密块数
    var invalidFormatBlocks: Int = 0    // 无效格式的加密块数
    var zipFoundationSuccess: Int = 0   // ZIPFoundation 成功次数
    var fallbackSuccess: Int = 0        // 回退方法成功次数
    
    /// 打印统计信息
    func printSummary() {
        print("=== 解压统计信息 ===")
        print("总条目数: \(totalBlocks)")
        print("成功解压: \(successfulBlocks)")
        print("无效格式: \(invalidFormatBlocks)")
        print("解压失败: \(failedBlocks)")
        print("额外字段: 0")  // 保持与原输出格式一致
        print("跳过条目: 0")  // 保持与原输出格式一致
        
        let successRate = totalBlocks > 0 ?
            Double(successfulBlocks) / Double(totalBlocks) * 100 : 0.0
        print("成功率: \(String(format: "%.2f", successRate))%")
        
        print("--- 详细信息 ---")
        print("ZIPFoundation成功: \(zipFoundationSuccess)")
        print("回退方法成功: \(fallbackSuccess)")
        print("==================")
    }
    
    /// 记录解压尝试
    mutating func recordAttempt() {
        totalBlocks += 1
    }
    
    /// 记录成功（指定使用的方法）
    mutating func recordSuccess(usingZipFoundation: Bool) {
        successfulBlocks += 1
        if usingZipFoundation {
            zipFoundationSuccess += 1
        } else {
            fallbackSuccess += 1
        }
    }
    
    /// 记录失败
    mutating func recordFailure() {
        failedBlocks += 1
    }
    
    /// 记录无效格式
    mutating func recordInvalidFormat() {
        invalidFormatBlocks += 1
        failedBlocks += 1  // 无效格式也算作失败
    }
}

// MARK: - Data 扩展方法
extension Data {
    /// 使用 ZIPFoundation 进行 GZIP 解压缩（不再使用，保留占位以兼容旧调用）
    func decompressGzipWithZipFoundation() throws -> (Data, Bool) {
        // 保留方法签名以避免编译错误，但直接抛出以走主路径
        throw LoganParseError.decompressionFailed
    }
    
    /// GZIP 解压缩（手动解析GZIP格式，提取deflate数据）
    func decompressGzipManually() throws -> Data {
        print("开始手动GZIP解压缩，数据大小: \(count)")
        print("数据头部: \(prefix(16).map { String(format: "%02x", $0) }.joined(separator: " "))")
        
        // 验证GZIP魔数
        guard count >= 10 && self[0] == 0x1f && self[1] == 0x8b else {
            print("不是有效的GZIP格式")
            throw LoganParseError.decompressionFailed
        }
        
        // 解析GZIP头部，跳过到deflate数据
        var offset = 10 // 基本头部长度
        
        // 检查标志位（第4字节）
        let flags = self[3]
        print("GZIP标志位: 0x\(String(format: "%02x", flags))")
        
        // 跳过额外字段
        if (flags & 0x04) != 0 { // FEXTRA
            guard offset + 2 <= count else {
                throw LoganParseError.decompressionFailed
            }
            let extraLen = Int(self[offset]) + (Int(self[offset + 1]) << 8)
            offset += 2 + extraLen
            print("发现额外字段，长度: \(extraLen)")
        }
        
        // 跳过原始文件名
        if (flags & 0x08) != 0 { // FNAME
            let nameStart = offset
            while offset < count && self[offset] != 0 {
                offset += 1
            }
            offset += 1 // 跳过null终止符
            let fileName = String(data: self.subdata(in: nameStart..<(offset-1)), encoding: .utf8) ?? "unknown"
            print("跳过原始文件名: \(fileName)")
        }
        
        // 跳过注释
        if (flags & 0x10) != 0 { // FCOMMENT
            let commentStart = offset
            while offset < count && self[offset] != 0 {
                offset += 1
            }
            offset += 1 // 跳过null终止符
            let comment = String(data: self.subdata(in: commentStart..<(offset-1)), encoding: .utf8) ?? "unknown"
            print("跳过注释: \(comment)")
        }
        
        // 跳过CRC16
        if (flags & 0x02) != 0 { // FHCRC
            offset += 2
            print("跳过CRC16校验")
        }
        
        print("GZIP头部长度: \(offset), deflate数据长度: \(count - offset - 8)")
        
        // 提取deflate数据（去掉头部和尾部8字节的CRC32+ISIZE）
        guard offset + 8 < count else {
            print("GZIP数据太短，无法包含deflate数据")
            throw LoganParseError.decompressionFailed
        }
        
        let deflateData = self.subdata(in: offset..<(count - 8))
        print("提取deflate数据，大小: \(deflateData.count)")
        print("deflate数据头部: \(deflateData.prefix(16).map { String(format: "%02x", $0) }.joined(separator: " "))")
        
        // 使用COMPRESSION_ZLIB解压deflate数据
        return try deflateData.withUnsafeBytes { bytes in
            let buffer = UnsafeBufferPointer<UInt8>(start: bytes.bindMemory(to: UInt8.self).baseAddress, count: deflateData.count)
            
            // 尝试不同的缓冲区大小
            let bufferSizes = [deflateData.count * 32, deflateData.count * 16, deflateData.count * 8, deflateData.count * 4, Swift.max(deflateData.count * 2, 64 * 1024)]
            
            for bufferSize in bufferSizes {
                let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
                defer { destinationBuffer.deallocate() }
                
                print("尝试deflate解压，缓冲区大小: \(bufferSize)")
                
                let decompressedSize = compression_decode_buffer(
                    destinationBuffer, bufferSize,
                    buffer.baseAddress!, deflateData.count,
                    nil, COMPRESSION_ZLIB
                )
                
                if decompressedSize > 0 {
                    print("deflate解压缩成功！缓冲区大小: \(bufferSize), 解压后大小: \(decompressedSize)")
                    return Data(bytes: destinationBuffer, count: decompressedSize)
                } else {
                    print("deflate解压失败，缓冲区大小: \(bufferSize), 错误码: \(decompressedSize)")
                }
            }
            
            print("所有deflate解压缩尝试都失败了")
            throw LoganParseError.decompressionFailed
        }
    }
    
    /// 统一的GZIP解压缩方法，带统计信息（主路径：GzipSwift，失败回退到手动）
    func decompressGzip(stats: inout DecompressionStats) throws -> Data {
        // 记录解压尝试
        stats.recordAttempt()
        
        // 验证 GZIP 魔数
        guard count >= 10 && self[0] == 0x1f && self[1] == 0x8b else {
            print("不是有效的GZIP格式")
            stats.recordInvalidFormat()
            throw LoganParseError.decompressionFailed
        }
        
        // 优先使用 GzipSwift
        do {
            let output = try self.gunzipped()
            print("GzipSwift 解压成功，大小: \(output.count)")
            stats.recordSuccess(usingZipFoundation: false)
            return output
        } catch {
            print("GzipSwift 解压失败，尝试回退: \(error)")
        }
        
        // 回退到手动解压
        do {
            let decompressedData = try decompressGzipManually()
            stats.recordSuccess(usingZipFoundation: false)
            return decompressedData
        } catch {
            print("GZIP 手动解压也失败: \(error)")
            stats.recordFailure()
            throw error
        }
    }
    
    /// 移除 PKCS7 填充
    func removePKCS7Padding() -> Data {
        guard !isEmpty else { return self }
        
        let paddingLength = Int(self[count - 1])
        if paddingLength == 0 || paddingLength > 16 || paddingLength > count {
            return self
        }
        
        // 验证填充是否正确
        let start = count - paddingLength
        for i in start..<count {
            if self[i] != self[count - 1] {
                return self // 填充不正确，返回原数据
            }
        }
        
        return self.prefix(start)
    }
}

// MARK: - Date 扩展方法
extension Date {
    /// ISO8601 字符串格式
    var iso8601String: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
}

// MARK: - Logan 日志条目模型
struct LoganLogItem: Identifiable, Codable {
    let id: UUID // 添加唯一标识符
    let content: String
    let flag: String
    let logTime: String
    let threadName: String
    let threadId: String
    let isMainThread: String
    
    // 自定义初始化器，自动生成UUID
    init(content: String, flag: String, logTime: String, threadName: String, threadId: String, isMainThread: String) {
        self.id = UUID()
        self.content = content
        self.flag = flag
        self.logTime = logTime
        self.threadName = threadName
        self.threadId = threadId
        self.isMainThread = isMainThread
    }
}

// MARK: - 设置服务协议
protocol SettingsService {
    func getSettings() -> LoganSettings
    func addParseHistory(_ history: ParseHistory)
}

// MARK: - 文件管理服务协议
protocol FileManagerService {
    func generateJsonFile(logItems: [LoganLogItem], originalFileName: String) async throws -> URL
}

// MARK: - Logan 设置模型
struct LoganSettings {
    let aesKey: String
    let aesIv: String
}

// MARK: - 日志工具
struct Logger {
    static let parser = "LoganParser"
    
    static func info(_ message: String, category: String) {
        print("[\(category)] INFO: \(message)")
    }
    
    static func error(_ message: String, category: String) {
        print("[\(category)] ERROR: \(message)")
    }
}

class LoganParserService: ObservableObject {
    @Published var isParsing = false
    @Published var parseProgress: Double = 0.0
    
    private let settingsService: SettingsService
    private let fileManagerService: FileManagerService
    
    // 统计加密块失败数量
    private var failedBlockCount = 0
    // 统计加密块成功数量
    private var successBlockCount = 0
    
    init(settingsService: SettingsService, fileManagerService: FileManagerService) {
        self.settingsService = settingsService
        self.fileManagerService = fileManagerService
    }
    
    /// 获取最近一次解析中失败的加密块数量
    func getFailedBlockCount() -> Int {
        return failedBlockCount
    }
    
    /// 获取最近一次解析中成功的加密块数量
    func getSuccessBlockCount() -> Int {
        return successBlockCount
    }
    
    /// 获取最近一次解析的加密块统计信息
    func getBlockStatistics() -> (success: Int, failed: Int, total: Int) {
        let total = successBlockCount + failedBlockCount
        return (success: successBlockCount, failed: failedBlockCount, total: total)
    }
    
    // 主解析方法
    func parseLogFile(at url: URL) async throws -> [LoganLogItem] {
        await MainActor.run { isParsing = true }
        defer { Task { @MainActor in isParsing = false } }
        
        Logger.info("开始解析 Logan 文件: \(url.path)", category: Logger.parser)
        
        do {
            // 读取文件数据
            let fileData = try Data(contentsOf: url)
            await updateProgress(0.1)
            
            // 解析 Logan 文件
            let decryptedContent = try await parseLoganFile(data: fileData)
            await updateProgress(0.7)
            
            // 解析日志内容
            let logItems = parseLogContent(decryptedContent)
            await updateProgress(0.9)
            
            // 生成 JSON 文件并拿到路径
            let jsonUrl = try await fileManagerService.generateJsonFile(
                logItems: logItems,
                originalFileName: url.lastPathComponent
            )
            await updateProgress(1.0)
            
            // 记录解析历史
            let history = ParseHistory(
                filePath: jsonUrl.path,
                fileName: jsonUrl.lastPathComponent,
                parseTime: Date(),
                fileSize: fileData.count,
                logCount: logItems.count,
                isSuccess: true,
                errorMessage: nil,
                jsonFilePath: jsonUrl.path
            )
            settingsService.addParseHistory(history)
            
            Logger.info("Logan 文件解析成功，共解析 \(logItems.count) 条日志", category: Logger.parser)
            return logItems
            
        } catch {
            Logger.error("Logan 文件解析失败: \(error.localizedDescription)", category: Logger.parser)
            
            // 记录失败历史
            let history = ParseHistory(
                filePath: url.path,
                fileName: url.lastPathComponent,
                parseTime: Date(),
                fileSize: 0,
                logCount: 0,
                isSuccess: false,
                errorMessage: error.localizedDescription,
                jsonFilePath: nil
            )
            settingsService.addParseHistory(history)
            
            throw error
        }
    }
    
    // 解析 Logan 文件格式
    private func parseLoganFile(data: Data) async throws -> String {
        var offset = 0
        var decryptedContent = ""
        let totalBytes = data.count
        var decompressionStats = DecompressionStats()  // 解压统计信息
        
        // 重置计数器
        failedBlockCount = 0
        successBlockCount = 0
        
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
                
                // 使用新的统一解压方法
                let decompressedData = try decryptedData.decompressGzip(stats: &decompressionStats)
                
                // 转换为字符串
                if let content = String(data: decompressedData, encoding: .utf8) {
                    decryptedContent += content
                }
                
                // 统计成功解密的加密块数量
                successBlockCount += 1
            } catch {
                // 统计加密块失败数量
                failedBlockCount += 1
                // 单个块解析失败，继续处理下一个块
                Logger.error("处理加密块失败 (第\(failedBlockCount)个): \(error)", category: Logger.parser)
                continue
            }
        }
        
        guard !decryptedContent.isEmpty else {
            throw LoganParseError.emptyResult
        }
        
        // 输出加密块统计信息
        let totalBlocks = successBlockCount + failedBlockCount
        Logger.info("解析完成，总共处理 \(totalBlocks) 个加密块：成功 \(successBlockCount) 个，失败 \(failedBlockCount) 个", category: Logger.parser)
        
        if failedBlockCount > 0 {
            Logger.error("警告：有 \(failedBlockCount) 个加密块解析失败，可能影响日志完整性", category: Logger.parser)
        }
        
        // 打印解压统计信息
        decompressionStats.printSummary()
        
        return decryptedContent
    }
    
    // AES 解密
    private func decryptAES(data: Data) throws -> Data {
        let settings = settingsService.getSettings()
        let keyString = settings.aesKey
        let ivString = settings.aesIv
        
        print("AES 解密开始 - 数据大小: \(data.count), 密钥: \(keyString), IV: \(ivString)")
        
        let key = keyString.data(using: .utf8)!
        let iv = ivString.data(using: .utf8)!
        
        print("密钥长度: \(key.count), IV长度: \(iv.count)")
        
        // 确保数据长度是16的倍数
        var dataToDecrypt = data
        if dataToDecrypt.count % 16 != 0 {
            let paddedLength = ((dataToDecrypt.count / 16) + 1) * 16
            var paddedData = Data(count: paddedLength)
            paddedData.replaceSubrange(0..<dataToDecrypt.count, with: dataToDecrypt)
            dataToDecrypt = paddedData
            print("数据填充到: \(dataToDecrypt.count) 字节")
        }
        
        // 使用 CommonCrypto 进行 AES/CBC 解密
        let decryptedData = try decryptAESCBC(data: dataToDecrypt, key: key, iv: iv)
        print("AES 解密完成，解密数据大小: \(decryptedData.count)")
        
        // 移除 PKCS7 填充
        let finalData = decryptedData.removePKCS7Padding()
        print("移除 PKCS7 填充后数据大小: \(finalData.count)")
        
        // 打印解密后数据的前几个字节
        let prefix = finalData.prefix(min(16, finalData.count))
        print("解密后前16字节: \(prefix.map { String(format: "%02x", $0) }.joined(separator: " "))")
        
        return finalData
    }
    
    // AES/CBC 解密实现（分块解密，与 Dart 版本一致）
    private func decryptAESCBC(data: Data, key: Data, iv: Data) throws -> Data {
        // 创建 CBC 模式的 AES 解密器
        var decryptedData = Data()
        var currentIV = iv
        
        // 分块解密，每次处理 16 字节
        var offset = 0
        while offset < data.count {
            let blockEnd = min(offset + 16, data.count)
            let block = data.subdata(in: offset..<blockEnd)
            
            // 只处理完整的 16 字节块
            if block.count == 16 {
                let decryptedBlock = try decryptSingleBlock(block: block, key: key, iv: currentIV)
                decryptedData.append(decryptedBlock)
                
                // 更新 IV 为当前加密块（CBC 模式特性）
                currentIV = block
            }
            
            offset += 16
        }
        
        return decryptedData
    }
    
    // 解密单个 AES 块
    private func decryptSingleBlock(block: Data, key: Data, iv: Data) throws -> Data {
        let cryptLength = size_t(16) // AES 块大小固定为 16 字节
        var cryptData = Data(count: cryptLength)
        
        let keyLength = size_t(key.count)
        let operation: CCOperation = UInt32(kCCDecrypt)
        let algorithm: CCAlgorithm = UInt32(kCCAlgorithmAES128)
        let options: CCOptions = 0 // NoPadding
        
        var numBytesDecrypted: size_t = 0
        
        let cryptStatus = key.withUnsafeBytes { keyBytes in
            iv.withUnsafeBytes { ivBytes in
                block.withUnsafeBytes { dataBytes in
                    cryptData.withUnsafeMutableBytes { cryptBytes in
                        CCCrypt(operation,
                               algorithm,
                               options,
                               keyBytes.bindMemory(to: UInt8.self).baseAddress,
                               keyLength,
                               ivBytes.bindMemory(to: UInt8.self).baseAddress,
                               dataBytes.bindMemory(to: UInt8.self).baseAddress,
                               block.count,
                               cryptBytes.bindMemory(to: UInt8.self).baseAddress,
                               cryptLength,
                               &numBytesDecrypted)
                    }
                }
            }
        }
        
        guard UInt32(cryptStatus) == UInt32(kCCSuccess) else {
            throw LoganParseError.decryptionFailed
        }
        
        return cryptData.prefix(numBytesDecrypted)
    }
    
    // 解析日志内容（与 Dart 版本完全一致）
    private func parseLogContent(_ content: String) -> [LoganLogItem] {
        var logItems: [LoganLogItem] = []
        
        // 按行分割内容
        let lines = content.components(separatedBy: .newlines)
        print("开始解析 \(lines.count) 行日志内容")
        
        var jsonSuccessCount = 0
        var nonJsonCount = 0
        var emptyLineCount = 0
        var invalidJsonCount = 0
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedLine.isEmpty {
                emptyLineCount += 1
                continue
            }
            
            do {
                // 尝试解析为 JSON
                guard let lineData = trimmedLine.data(using: .utf8) else {
                    print("无法转换为UTF8数据: \(trimmedLine.prefix(50))")
                    continue
                }
                let jsonData = try JSONSerialization.jsonObject(with: lineData)
                
                if let jsonDict = jsonData as? [String: Any] {
                    // 使用正确的 Logan JSON 格式
                    let logItem = LoganLogItem(
                        content: (jsonDict["c"] as? CustomStringConvertible)?.description ?? "",
                        flag: (jsonDict["f"] as? CustomStringConvertible)?.description ?? "3",
                        logTime: formatLogTime(jsonDict["l"]),
                        threadName: (jsonDict["n"] as? CustomStringConvertible)?.description ?? "unknown",
                        threadId: (jsonDict["i"] as? CustomStringConvertible)?.description ?? "0",
                        isMainThread: (jsonDict["m"] as? CustomStringConvertible)?.description ?? "false"
                    )
                    logItems.append(logItem)
                    jsonSuccessCount += 1
                } else {
                    // JSON解析成功但不是字典类型
                    print("JSON解析成功但不是字典类型: \(trimmedLine.prefix(100))")
                    invalidJsonCount += 1
                }
            } catch {
                // 如果不是 JSON 格式，创建一个简单的日志项
                let logItem = LoganLogItem(
                    content: trimmedLine,
                    flag: "3", // 默认为提示信息
                    logTime: Date().iso8601String,
                    threadName: "unknown",
                    threadId: "0",
                    isMainThread: "false"
                )
                logItems.append(logItem)
                nonJsonCount += 1
            }
        }
        
        print("解析统计: 总行数=\(lines.count), 空行=\(emptyLineCount), JSON成功=\(jsonSuccessCount), 非JSON=\(nonJsonCount), 无效JSON=\(invalidJsonCount), 最终条数=\(logItems.count)")
        
        return logItems
    }
    
    // 时间格式化（与 Dart 版本完全一致）
    private func formatLogTime(_ timeValue: Any?) -> String {
        guard let timeValue = timeValue else {
            return Date().iso8601String
        }
        
        var timestamp: Int64
        
        if let stringValue = timeValue as? String {
            guard let parsedValue = Int64(stringValue) else {
                return Date().iso8601String
            }
            timestamp = parsedValue
        } else if let numberValue = timeValue as? NSNumber {
            timestamp = numberValue.int64Value
        } else {
            return Date().iso8601String
        }
        
        // Logan 使用毫秒时间戳
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
        return date.iso8601String
    }
    
    // 更新进度
    @MainActor
    private func updateProgress(_ progress: Double) {
        parseProgress = progress
    }
}

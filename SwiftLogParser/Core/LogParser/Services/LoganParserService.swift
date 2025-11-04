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
import SwiftUI

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

// MARK: - Data 扩展方法
extension Data {
    /// 读取大端序 UInt32
    func readUInt32BigEndian(at offset: Int) -> UInt32? {
        guard offset + 4 <= count else { return nil }
        
        // 提取4个字节并手动组合为大端序整数
        let byte0 = UInt32(self[offset])
        let byte1 = UInt32(self[offset + 1])
        let byte2 = UInt32(self[offset + 2])
        let byte3 = UInt32(self[offset + 3])
        
        // 大端序：高位字节在前
        return (byte0 << 24) | (byte1 << 16) | (byte2 << 8) | byte3
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
    let id: UUID
    let content: String
    let flag: String
    let logTime: String
    let threadName: String
    let threadId: String
    let isMainThread: String
    
    // 根据 flag 解析得到的日志类型（可选）
    var logType: LogType? {
        LogType.from(stringValue: flag)
    }
    
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
    
    /// 日志类型颜色
    var logTypeColor: Color {
        guard let logType = logType else {
            return .gray
        }
        return logType.color
    }
    
    /// 日志类型显示名称
    var logTypeDisplayName: String {
        guard let logType = logType else {
            return "未知"
        }
        return logType.displayName
    }
    
    /// 日志类型图标名称
    var logTypeIconName: String {
        guard let logType = logType else {
            return "questionmark.circle"
        }
        return logType.iconName
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

// MARK: - Logan 解析服务
class LoganParserService: ObservableObject {
    @Published var isParsing = false
    @Published var parseProgress: Double = 0.0
    
    private let settingsService: SettingsService
    private let fileManagerService: FileManagerService
    
    // 统计信息
    private var failedBlockCount = 0
    private var successBlockCount = 0
    
    init(settingsService: SettingsService, fileManagerService: FileManagerService) {
        self.settingsService = settingsService
        self.fileManagerService = fileManagerService
    }
    
    /// 获取加密块统计信息
    func getBlockStatistics() -> (success: Int, failed: Int, total: Int) {
        let total = successBlockCount + failedBlockCount
        return (success: successBlockCount, failed: failedBlockCount, total: total)
    }
    
    // MARK: - 主解析方法
    func parseLogFile(at url: URL) async throws -> [LoganLogItem] {
        await MainActor.run { isParsing = true }
        defer { Task { @MainActor in isParsing = false } }
        
        Logger.info("开始解析 Logan 文件: \(url.path)", category: Logger.parser)
        
        do {
            // 1. 读取文件数据
            let fileData = try Data(contentsOf: url)
            await updateProgress(0.1)
            
            // 2. 解析 Logan 文件格式
            let decryptedContent = try await parseLoganFile(data: fileData)
            await updateProgress(0.7)
            
            // 3. 解析日志内容
            let logItems = parseLogContent(decryptedContent)
            await updateProgress(0.9)
            
            // 4. 生成 JSON 文件
            let jsonUrl = try await fileManagerService.generateJsonFile(
                logItems: logItems,
                originalFileName: url.lastPathComponent
            )
            await updateProgress(1.0)
            
            // 5. 记录解析历史
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
    
    // MARK: - 解析 Logan 文件格式
    private func parseLoganFile(data: Data) async throws -> String {
        var offset = 0
        var decryptedContent = ""
        let totalBytes = data.count
        
        // 重置统计计数器
        failedBlockCount = 0
        successBlockCount = 0
        
        var totalLinesFromBlocks = 0  // 统计所有块的总行数
        
        while offset < data.count {
            // 更新进度
            let progress = 0.1 + (Double(offset) / Double(totalBytes)) * 0.6
            await updateProgress(progress)
            
            // 1. 查找标识符
            guard offset < data.count else { break }
            
            let marker = data[offset]
            if marker != LoganConstants.encryptContentStart {
                offset += 1
                continue
            }
            
            offset += 1  // 跳过标识符
            
            // 2. 读取加密长度（大端序）
            guard let encryptedLength = data.readUInt32BigEndian(at: offset) else {
                break
            }
            offset += 4
            
            // 3. 读取加密数据
            guard offset + Int(encryptedLength) <= data.count else {
                break
            }
            
            let encryptedData = data[offset..<offset + Int(encryptedLength)]
            offset += Int(encryptedLength)
            
            do {
                let blockNumber = successBlockCount + failedBlockCount + 1
                print("--- 处理第 \(blockNumber) 个加密块 ---")
                print("加密数据长度: \(encryptedData.count)")
                print("加密数据前16字节: \(encryptedData.prefix(16).map { String(format: "%02x", $0) }.joined(separator: " "))")
                
                // 4. 解密
                let decryptedData = try decryptAES(data: Data(encryptedData))
                print("解密后数据长度: \(decryptedData.count)")
                print("解密后前16字节: \(decryptedData.prefix(16).map { String(format: "%02x", $0) }.joined(separator: " "))")
                
                // 验证GZIP魔数
                if decryptedData.count >= 2 {
                    let magic1 = decryptedData[0]
                    let magic2 = decryptedData[1]
                    print("GZIP魔数: 0x\(String(format: "%02x", magic1)) 0x\(String(format: "%02x", magic2)) (期望: 0x1f 0x8b)")
                    
                    if magic1 != 0x1f || magic2 != 0x8b {
                        print("⚠️ 警告: GZIP魔数不正确，可能解密失败")
                    }
                }
                
                // 5. 解压缩（带回退机制）
                var decompressedData: Data
                do {
                    decompressedData = try decryptedData.gunzipped()
                    print("使用Gzip库解压成功")
                } catch {
                    print("Gzip库解压失败，尝试手动解压: \(error)")
                    decompressedData = try decompressGzipManually(data: decryptedData)
                    print("手动解压成功")
                }
                print("解压后数据长度: \(decompressedData.count)")
                
                // 6. 转换为字符串
                if let content = String(data: decompressedData, encoding: .utf8) {
                    let allLines = content.split(separator: "\n", omittingEmptySubsequences: false)
                    let nonEmptyLines = allLines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    print("本块内容: 总行数=\(allLines.count), 非空行=\(nonEmptyLines.count)")
                    totalLinesFromBlocks += nonEmptyLines.count
                    
                    // 确保块之间正确拼接：如果当前内容不为空且上一个块末尾没有换行符，添加换行符
                    if !decryptedContent.isEmpty && !decryptedContent.hasSuffix("\n") && !content.isEmpty {
                        print("⚠️ 添加换行符以分隔块")
                        decryptedContent += "\n"
                    }
                    
                    decryptedContent += content
                    
                    // 检查当前块末尾是否有换行符
                    if !content.isEmpty && !content.hasSuffix("\n") {
                        print("⚠️ 本块内容末尾没有换行符")
                    }
                } else {
                    print("⚠️ 警告: 无法将解压数据转换为UTF8字符串")
                }
                
                successBlockCount += 1
                print("✓ 第 \(blockNumber) 个加密块处理成功\n")
            } catch {
                failedBlockCount += 1
                let blockNumber = successBlockCount + failedBlockCount
                print("✗ 第 \(blockNumber) 个加密块处理失败")
                Logger.error("处理加密块失败: \(error)", category: Logger.parser)
                
                // 打印更详细的错误信息
                if let gzipError = error as? GzipError {
                    print("GZIP错误详情: \(gzipError)")
                }
                print("")
                continue
            }
        }
        
        guard !decryptedContent.isEmpty else {
            throw LoganParseError.emptyResult
        }
        
        let totalBlocks = successBlockCount + failedBlockCount
        Logger.info("解析完成，总共 \(totalBlocks) 个加密块：成功 \(successBlockCount)，失败 \(failedBlockCount)", category: Logger.parser)
        
        print("=== 解密内容统计 ===")
        print("所有块累计非空行数: \(totalLinesFromBlocks)")
        print("合并后内容长度: \(decryptedContent.count) 字符")
        
        return decryptedContent
    }
    
    // MARK: - AES 解密（按照文档的分块解密方式）
    private func decryptAES(data: Data) throws -> Data {
        let settings = settingsService.getSettings()
        
        guard let key = settings.aesKey.data(using: .utf8),
              let iv = settings.aesIv.data(using: .utf8) else {
            throw LoganParseError.decryptionFailed
        }
        
        print("  AES解密 - 密钥长度: \(key.count), IV长度: \(iv.count)")
        
        // 确保数据长度是16的倍数（AES块大小）
        var dataToDecrypt = data
        let originalLength = data.count
        if dataToDecrypt.count % 16 != 0 {
            let paddedLength = ((dataToDecrypt.count / 16) + 1) * 16
            var paddedData = Data(count: paddedLength)
            paddedData.replaceSubrange(0..<dataToDecrypt.count, with: dataToDecrypt)
            dataToDecrypt = paddedData
            print("  数据填充: \(originalLength) -> \(paddedLength) 字节")
        }
        
        // 分块解密（CBC模式）
        var decryptedData = Data()
        var currentIV = iv
        var offset = 0
        var blockCount = 0
        
        while offset < dataToDecrypt.count {
            let blockEnd = min(offset + 16, dataToDecrypt.count)
            let block = dataToDecrypt.subdata(in: offset..<blockEnd)
            
            // 只处理完整的16字节块
            if block.count == 16 {
                blockCount += 1
                let decryptedBlock = try decryptSingleBlock(block: block, key: key, iv: currentIV)
                decryptedData.append(decryptedBlock)
                
                // CBC模式：下一个块的IV是当前加密块
                currentIV = block
            }
            
            offset += 16
        }
        
        print("  解密了 \(blockCount) 个AES块，总长度: \(decryptedData.count) 字节")
        
        // 移除PKCS7填充
        let unpaddedData = removePKCS7Padding(from: decryptedData)
        if unpaddedData.count != decryptedData.count {
            print("  移除PKCS7填充: \(decryptedData.count) -> \(unpaddedData.count) 字节")
        }
        
        return unpaddedData
    }
    
    // 解密单个AES块（无填充）
    private func decryptSingleBlock(block: Data, key: Data, iv: Data) throws -> Data {
        let cryptLength = 16  // AES块大小固定为16字节
        var cryptData = Data(count: cryptLength)
        
        var numBytesDecrypted: size_t = 0
        
        let cryptStatus = key.withUnsafeBytes { keyBytes in
            iv.withUnsafeBytes { ivBytes in
                block.withUnsafeBytes { dataBytes in
                    cryptData.withUnsafeMutableBytes { cryptBytes in
                        CCCrypt(
                            CCOperation(kCCDecrypt),
                            CCAlgorithm(kCCAlgorithmAES),
                            CCOptions(0),  // 无填充
                            keyBytes.baseAddress, key.count,
                            ivBytes.baseAddress,
                            dataBytes.baseAddress, block.count,
                            cryptBytes.baseAddress, cryptLength,
                            &numBytesDecrypted
                        )
                    }
                }
            }
        }
        
        guard cryptStatus == kCCSuccess else {
            throw LoganParseError.decryptionFailed
        }
        
        return cryptData.prefix(numBytesDecrypted)
    }
    
    // 移除PKCS7填充
    private func removePKCS7Padding(from data: Data) -> Data {
        guard !data.isEmpty else { return data }
        
        let paddingLength = Int(data[data.count - 1])
        
        // 验证填充长度的合理性
        if paddingLength == 0 || paddingLength > 16 || paddingLength > data.count {
            return data
        }
        
        // 验证所有填充字节的值是否正确
        let start = data.count - paddingLength
        for i in start..<data.count {
            if data[i] != data[data.count - 1] {
                return data  // 填充不正确，返回原数据
            }
        }
        
        // 移除填充
        return data.prefix(start)
    }
    
    // MARK: - 解析日志内容
    private func parseLogContent(_ content: String) -> [LoganLogItem] {
        var logItems: [LoganLogItem] = []
        
        // 使用与 Dart 相同的分割方式：按 \n 分割
        let lines = content.split(separator: "\n", omittingEmptySubsequences: false).map { String($0) }
        
        print("开始解析日志内容")
        print("原始内容长度: \(content.count) 字符")
        print("分割后行数: \(lines.count)")
        
        var jsonSuccessCount = 0
        var nonJsonCount = 0
        var emptyLineCount = 0
        var skippedLineCount = 0
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // 与 Dart 版本一致：空行直接跳过
            if trimmedLine.isEmpty {
                emptyLineCount += 1
                continue
            }
            
            // 尝试解析为 JSON
            do {
                guard let lineData = trimmedLine.data(using: .utf8) else {
                    print("第 \(index + 1) 行: 无法转换为UTF8")
                    // 无法转换为UTF8，作为纯文本处理
                    let logItem = LoganLogItem(
                        content: trimmedLine,
                        flag: "3",
                        logTime: Date().iso8601String,
                        threadName: "unknown",
                        threadId: "0",
                        isMainThread: "false"
                    )
                    logItems.append(logItem)
                    nonJsonCount += 1
                    continue
                }
                
                let jsonData = try JSONSerialization.jsonObject(with: lineData)
                
                if let json = jsonData as? [String: Any] {
                    // 使用正确的 Logan JSON 格式
                    let logItem = LoganLogItem(
                        content: json["c"] as? String ?? "",
                        flag: json["f"] as? String ?? "3",
                        logTime: formatLogTime(json["l"]),
                        threadName: json["n"] as? String ?? "unknown",
                        threadId: json["i"] as? String ?? "0",
                        isMainThread: json["m"] as? String ?? "false"
                    )
                    logItems.append(logItem)
                    jsonSuccessCount += 1
                } else {
                    print("第 \(index + 1) 行: JSON不是字典类型")
                    // JSON解析成功但不是字典类型，作为纯文本处理
                    let logItem = LoganLogItem(
                        content: trimmedLine,
                        flag: "3",
                        logTime: Date().iso8601String,
                        threadName: "unknown",
                        threadId: "0",
                        isMainThread: "false"
                    )
                    logItems.append(logItem)
                    nonJsonCount += 1
                }
            } catch {
                // 如果不是 JSON 格式，创建一个简单的日志项
                if nonJsonCount < 5 {  // 只打印前5个非JSON行
                    print("第 \(index + 1) 行: JSON解析失败 - \(trimmedLine.prefix(50))")
                }
                let logItem = LoganLogItem(
                    content: trimmedLine,
                    flag: "3",
                    logTime: Date().iso8601String,
                    threadName: "unknown",
                    threadId: "0",
                    isMainThread: "false"
                )
                logItems.append(logItem)
                nonJsonCount += 1
            }
        }
        
        print("=== 日志解析统计 ===")
        print("总行数: \(lines.count)")
        print("空行: \(emptyLineCount)")
        print("JSON成功: \(jsonSuccessCount)")
        print("非JSON: \(nonJsonCount)")
        print("跳过: \(skippedLineCount)")
        print("最终日志条数: \(logItems.count)")
        print("预期条数: \(lines.count - emptyLineCount)")
        
        let expectedCount = lines.count - emptyLineCount
        if logItems.count != expectedCount {
            print("⚠️ 警告: 日志条数不匹配！差异: \(expectedCount - logItems.count)")
        }
        
        return logItems
    }
    
    // MARK: - 手动GZIP解压（回退方案）
    private func decompressGzipManually(data: Data) throws -> Data {
        print("  开始手动GZIP解压，数据大小: \(data.count)")
        
        // 验证GZIP魔数
        guard data.count >= 10 && data[0] == 0x1f && data[1] == 0x8b else {
            print("  不是有效的GZIP格式")
            throw LoganParseError.decompressionFailed
        }
        
        // 方法1: 尝试使用 zlib 直接解压整个 GZIP 数据
        print("  尝试方法1: 使用 zlib 解压完整 GZIP 数据")
        do {
            let decompressed = try decompressWithZlib(data: data, skipGzipHeader: false)
            print("  方法1成功，解压后大小: \(decompressed.count)")
            return decompressed
        } catch {
            print("  方法1失败: \(error)")
        }
        
        // 方法2: 手动解析 GZIP 头部，然后解压 deflate 数据
        print("  尝试方法2: 手动解析 GZIP 头部")
        
        var offset = 10  // 基本头部长度
        let flags = data[3]
        print("  GZIP标志位: 0x\(String(format: "%02x", flags))")
        
        // 跳过额外字段
        if (flags & 0x04) != 0 {  // FEXTRA
            guard offset + 2 <= data.count else {
                throw LoganParseError.decompressionFailed
            }
            let extraLen = Int(data[offset]) + (Int(data[offset + 1]) << 8)
            offset += 2 + extraLen
            print("  跳过额外字段，长度: \(extraLen)")
        }
        
        // 跳过原始文件名
        if (flags & 0x08) != 0 {  // FNAME
            while offset < data.count && data[offset] != 0 {
                offset += 1
            }
            offset += 1
            print("  跳过原始文件名")
        }
        
        // 跳过注释
        if (flags & 0x10) != 0 {  // FCOMMENT
            while offset < data.count && data[offset] != 0 {
                offset += 1
            }
            offset += 1
            print("  跳过注释")
        }
        
        // 跳过CRC16
        if (flags & 0x02) != 0 {  // FHCRC
            offset += 2
            print("  跳过CRC16校验")
        }
        
        print("  GZIP头部长度: \(offset), deflate数据长度: \(data.count - offset - 8)")
        
        // 提取deflate数据（去掉头部和尾部8字节的CRC32+ISIZE）
        guard offset + 8 < data.count else {
            print("  GZIP数据太短")
            throw LoganParseError.decompressionFailed
        }
        
        let deflateData = data.subdata(in: offset..<(data.count - 8))
        print("  提取deflate数据，大小: \(deflateData.count)")
        
        // 尝试解压 deflate 数据
        do {
            let decompressed = try decompressWithZlib(data: deflateData, skipGzipHeader: true)
            print("  方法2成功，解压后大小: \(decompressed.count)")
            return decompressed
        } catch {
            print("  方法2失败: \(error)")
            throw LoganParseError.decompressionFailed
        }
    }
    
    // 使用 zlib 解压数据
    private func decompressWithZlib(data: Data, skipGzipHeader: Bool) throws -> Data {
        return try data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> Data in
            guard let baseAddress = bytes.baseAddress?.assumingMemoryBound(to: UInt8.self) else {
                throw LoganParseError.decompressionFailed
            }
            
            // 尝试不同的缓冲区大小
            let bufferSizes = [
                data.count * 64,
                data.count * 32,
                data.count * 16,
                data.count * 8,
                data.count * 4,
                max(data.count * 2, 64 * 1024)
            ]
            
            for bufferSize in bufferSizes {
                let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
                defer { destinationBuffer.deallocate() }
                
                // 根据是否跳过 GZIP 头部选择不同的算法
                let algorithm: compression_algorithm = skipGzipHeader ? COMPRESSION_ZLIB : COMPRESSION_LZFSE
                
                // 先尝试 COMPRESSION_ZLIB
                var decompressedSize = compression_decode_buffer(
                    destinationBuffer, bufferSize,
                    baseAddress, data.count,
                    nil, COMPRESSION_ZLIB
                )
                
                // 如果失败，尝试 COMPRESSION_LZMA
                if decompressedSize == 0 {
                    decompressedSize = compression_decode_buffer(
                        destinationBuffer, bufferSize,
                        baseAddress, data.count,
                        nil, COMPRESSION_LZMA
                    )
                }
                
                if decompressedSize > 0 {
                    return Data(bytes: destinationBuffer, count: decompressedSize)
                }
            }
            
            throw LoganParseError.decompressionFailed
        }
    }
    
    // MARK: - 时间格式化
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
        
        // Logan 使用毫秒时间戳
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1000.0)
        return date.iso8601String
    }
    
    // MARK: - 更新进度
    @MainActor
    private func updateProgress(_ progress: Double) {
        parseProgress = progress
    }
}

//
//  logan_parser_service.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/5.
//

import Foundation
import Combine
import CommonCrypto
import Compression

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
    /// GZIP 解压缩（与 Dart 版本一致，只使用标准 GZIP）
    func decompressGzipComplete() throws -> Data {
        // 使用标准 GZIP 解压缩，与 Dart 的 GZipDecoder 一致
        return try self.withUnsafeBytes { bytes in
            let buffer = UnsafeBufferPointer<UInt8>(start: bytes.bindMemory(to: UInt8.self).baseAddress, count: count)
            let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: count * 8)
            defer { destinationBuffer.deallocate() }
            
            let decompressedSize = compression_decode_buffer(
                destinationBuffer, count * 8,
                buffer.baseAddress!, count,
                nil, COMPRESSION_ZLIB
            )
            
            guard decompressedSize > 0 else {
                throw LoganParseError.decompressionFailed
            }
            
            return Data(bytes: destinationBuffer, count: decompressedSize)
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
struct LoganLogItem {
    let content: String
    let flag: String
    let logTime: String
    let threadName: String
    let threadId: String
    let isMainThread: String
}

// MARK: - 解析历史模型
struct ParseHistory {
    let filePath: String
    let fileName: String
    let parseTime: Date
    let fileSize: Int
    let logCount: Int
    let isSuccess: Bool
    let errorMessage: String?
}

// MARK: - 设置服务协议
protocol SettingsService {
    func getSettings() -> LoganSettings
    func addParseHistory(_ history: ParseHistory)
}

// MARK: - 文件管理服务协议
protocol FileManagerService {
    func generateJsonFile(logItems: [LoganLogItem], originalFileName: String) async throws
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
    
    init(settingsService: SettingsService, fileManagerService: FileManagerService) {
        self.settingsService = settingsService
        self.fileManagerService = fileManagerService
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
            
            // 生成 JSON 文件
            try await fileManagerService.generateJsonFile(
                logItems: logItems,
                originalFileName: url.lastPathComponent
            )
            await updateProgress(1.0)
            
            // 记录解析历史
            let history = ParseHistory(
                filePath: url.path,
                fileName: url.lastPathComponent,
                parseTime: Date(),
                fileSize: fileData.count,
                logCount: logItems.count,
                isSuccess: true,
                errorMessage: nil
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
                errorMessage: error.localizedDescription
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
                let decompressedData = try decryptedData.decompressGzipComplete()
                
                // 转换为字符串
                if let content = String(data: decompressedData, encoding: .utf8) {
                    decryptedContent += content
                }
            } catch {
                // 单个块解析失败，继续处理下一个块
                Logger.error("处理加密块失败: \(error)", category: Logger.parser)
                continue
            }
        }
        
        guard !decryptedContent.isEmpty else {
            throw LoganParseError.emptyResult
        }
        
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
        
        do {
            // 按行分割内容
            let lines = content.components(separatedBy: .newlines)
            print("开始解析 \(lines.count) 行日志内容")
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedLine.isEmpty else { continue }
                
                do {
                    // 尝试解析为 JSON
                    guard let lineData = trimmedLine.data(using: .utf8) else { continue }
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
                }
            }
        } catch {
            print("解析日志内容失败: \(error)")
            
            // 如果解析失败，将整个内容作为一条日志（与 Dart 版本一致）
            let logItem = LoganLogItem(
                content: content,
                flag: "4", // 错误信息
                logTime: Date().iso8601String,
                threadName: "parser",
                threadId: "0",
                isMainThread: "false"
            )
            logItems.append(logItem)
        }
        
        return logItems
    }
    
    // 时间格式化（与 Dart 版本完全一致）
    private func formatLogTime(_ timeValue: Any?) -> String {
        guard let timeValue = timeValue else {
            return Date().iso8601String
        }
        
        do {
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
        } catch {
            print("时间格式化失败: \(error), 原始值: \(timeValue)")
            return Date().iso8601String
        }
    }
    
    // 更新进度
    @MainActor
    private func updateProgress(_ progress: Double) {
        parseProgress = progress
    }
}

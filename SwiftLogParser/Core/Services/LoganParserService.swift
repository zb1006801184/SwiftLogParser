//
//  LoganParserService.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/5.
//

import Foundation
import Combine
import CommonCrypto
import Compression

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
            Logger.info("文件大小: \(fileData.count) 字节", category: Logger.parser)
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
    
    // 解析 Logan 文件格式 - 参考 Dart 代码逻辑
    private func parseLoganFile(data: Data) async throws -> String {
        var offset = 0
        var decryptedContent = ""
        let totalBytes = data.count
        var processedBlocks = 0
        var failedBlocks = 0
        
        Logger.info("开始解析文件，总大小: \(totalBytes) 字节", category: Logger.parser)
        
        // 如果文件太小，直接返回错误
        guard totalBytes > 5 else {
            Logger.error("文件太小，无法解析 Logan 格式", category: Logger.parser)
            throw LoganParseError.invalidFileFormat
        }
        
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
            guard offset + 4 <= data.count else {
                Logger.info("文件末尾数据不足4字节，跳过", category: Logger.parser)
                break
            }
            
            // 使用 ByteData 方式读取大端序 UInt32
            let encryptedLength = data.withUnsafeBytes { bytes in
                let pointer = bytes.bindMemory(to: UInt8.self).baseAddress! + offset
                return UInt32(pointer[0]) << 24 |
                       UInt32(pointer[1]) << 16 |
                       UInt32(pointer[2]) << 8 |
                       UInt32(pointer[3])
            }
            offset += 4
            
            Logger.debug("找到加密块，长度: \(encryptedLength)", category: Logger.parser)
            
            // 验证数据块长度合理性
            let blockLength = Int(encryptedLength)
            if blockLength <= 0 || blockLength > data.count - offset {
                Logger.error("无效的块长度: \(blockLength)，剩余数据: \(data.count - offset)，跳过此块", category: Logger.parser)
                failedBlocks += 1
                continue
            }
            
            // 提取加密数据块
            guard offset + blockLength <= data.count else {
                Logger.error("声明的块长度(\(blockLength))越界，剩余数据: \(data.count - offset)，跳过剩余数据", category: Logger.parser)
                break
            }
            let encryptedData = data.subdata(in: offset..<(offset + blockLength))
            offset += blockLength
            
            do {
                // 解密数据块
                let decryptedData = try decryptAES(data: encryptedData)
                
                // GZIP 解压缩
                let decompressedData = try decompressGzip(data: decryptedData)
                
                // 转换为字符串
                let content = convertToString(data: decompressedData)
                if !content.isEmpty {
                    decryptedContent += content
                    processedBlocks += 1
                    Logger.debug("成功处理块 \(processedBlocks)，大小: \(blockLength) 字节，内容长度: \(content.count)", category: Logger.parser)
                } else {
                    Logger.debug("块 \(processedBlocks + 1) 解析后内容为空", category: Logger.parser)
                }
            } catch {
                // 单个块解析失败，继续处理下一个块
                Logger.error("处理加密块失败: \(error.localizedDescription)，块大小: \(blockLength)", category: Logger.parser)
                failedBlocks += 1
                continue
            }
        }
        
        Logger.info("解析完成，成功处理: \(processedBlocks) 个块，失败: \(failedBlocks) 个块", category: Logger.parser)
        
        // 增加更详细的调试信息
        if decryptedContent.isEmpty {
            if processedBlocks == 0 && failedBlocks == 0 {
                Logger.error("未找到任何有效的加密块", category: Logger.parser)
                throw LoganParseError.invalidFileFormat
            } else if processedBlocks == 0 {
                Logger.error("所有块解析失败，可能是密钥错误", category: Logger.parser)
                throw LoganParseError.decryptionFailed
            } else {
                Logger.error("解析到 \(processedBlocks) 个块，但内容为空", category: Logger.parser)
                throw LoganParseError.emptyResult
            }
        }
        
        return decryptedContent
    }
    
    // AES 解密 - 参考 Dart 代码的分块解密逻辑
    private func decryptAES(data: Data) throws -> Data {
        let settings = settingsService.getSettings()
        let keyString = settings.aesKey
        let ivString = settings.aesIv
        
        guard let key = keyString.data(using: .utf8),
              let iv = ivString.data(using: .utf8) else {
            throw LoganParseError.decryptionFailed
        }
        
        // 确保数据长度是16的倍数（AES块大小）
        var dataToDecrypt = data
        if dataToDecrypt.count % 16 != 0 {
            let paddedLength = ((dataToDecrypt.count / 16) + 1) * 16
            var paddedData = Data(count: paddedLength)
            paddedData.replaceSubrange(0..<dataToDecrypt.count, with: dataToDecrypt)
            dataToDecrypt = paddedData
        }
        
        // 使用 AES/CBC/NoPadding 模式解密
        let decryptedData = try decryptAESCBC(
            data: dataToDecrypt,
            key: key,
            iv: iv,
            options: 0
        )
        
        // 手动移除 PKCS7 填充
        return decryptedData.removePKCS7Padding()
    }
    
    // AES/CBC 解密实现（使用 CommonCrypto）
    private func decryptAESCBC(data: Data, key: Data, iv: Data, options: CCOptions) throws -> Data {
        let cryptLength = size_t(data.count + kCCBlockSizeAES128)
        var cryptData = Data(count: cryptLength)
        
        let keyLength = size_t(kCCKeySizeAES128)
        let operation: CCOperation = UInt32(kCCDecrypt)
        let algorithm: CCAlgorithm = UInt32(kCCAlgorithmAES128)
        
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
    
    // GZIP 解压缩 - 改进版本，增加更详细的错误处理和重试机制
    private func decompressGzip(data: Data) throws -> Data {
        Logger.debug("开始 GZIP 解压缩，数据大小: \(data.count) 字节",
                    category: Logger.parser)
        
        // 检查数据是否太小
        guard data.count > 0 else {
            Logger.error("解压缩数据为空", category: Logger.parser)
            throw LoganParseError.decompressionFailed
        }
        
        // 输出数据头部用于调试
        let dataHex = data.prefix(min(16, data.count)).map {
            String(format: "%02x", $0)
        }.joined(separator: " ")
        Logger.debug("解压缩数据头部: \(dataHex)", category: Logger.parser)
        
        do {
            let result = try data.decompressGzipComplete()
            Logger.debug("GZIP 解压缩成功，输出大小: \(result.count) 字节",
                        category: Logger.parser)
            return result
        } catch {
            Logger.error("GZIP 解压缩失败: \(error.localizedDescription)",
                        category: Logger.parser)
            
            // 尝试备用解压缩方法
            Logger.debug("尝试备用解压缩方法", category: Logger.parser)
            
            // 方法1: 直接使用 ZLIB
            do {
                let result = try data.decompress(using: COMPRESSION_ZLIB)
                Logger.debug("ZLIB 备用解压缩成功，输出大小: \(result.count) 字节",
                            category: Logger.parser)
                return result
            } catch {
                Logger.debug("ZLIB 备用解压缩失败: \(error)", category: Logger.parser)
            }
            
            // 方法2: 检查是否为未压缩数据
            if data.isLikelyUncompressedText() {
                Logger.debug("数据似乎未压缩，直接返回原数据", category: Logger.parser)
                return data
            }
            
            // 方法3: 尝试跳过可能的头部数据
            if data.count > 10 {
                let trimmedData = data.dropFirst(2) // 跳过前2字节
                do {
                    let result = try trimmedData.decompress(using: COMPRESSION_ZLIB)
                    Logger.debug("跳过头部后解压缩成功，输出大小: \(result.count) 字节",
                                category: Logger.parser)
                    return result
                } catch {
                    Logger.debug("跳过头部解压缩失败: \(error)", category: Logger.parser)
                }
            }
            
            throw LoganParseError.decompressionFailed
        }
    }
    
    // 改进的字符串转换方法
    private func convertToString(data: Data) -> String {
        // 尝试 UTF-8 编码
        if let string = String(data: data, encoding: .utf8) {
            return string
        }
        
        // 尝试其他编码
        let encodings: [String.Encoding] = [.utf16, .ascii, .isoLatin1]
        for encoding in encodings {
            if let string = String(data: data, encoding: encoding) {
                Logger.debug("使用 \(encoding) 编码成功转换字符串", category: Logger.parser)
                return string
            }
        }
        
        // 使用容错的 UTF-8 解码
        let string = String(decoding: data, as: UTF8.self)
        Logger.info("使用容错 UTF-8 解码，可能包含替换字符", category: Logger.parser)
        return string
    }
    
    // 解析日志内容 - 使用正确的 Logan JSON 字段映射
    private func parseLogContent(_ content: String) -> [LoganLogItem] {
        var logItems: [LoganLogItem] = []
        var skippedLines = 0
        var processedLines = 0
        
        Logger.info("开始解析日志内容，总字符数: \(content.count)", category: Logger.parser)
        
        // 按行分割内容
        let lines = content.components(separatedBy: .newlines)
        Logger.info("分割得到行数: \(lines.count)", category: Logger.parser)
        
        for (index, line) in lines.enumerated() {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            // 跳过空行但记录数量
            guard !trimmedLine.isEmpty else {
                skippedLines += 1
                continue
            }
            
            // 尝试解析 JSON 格式的日志
            if let logItem = parseJSONLogLine(trimmedLine, lineNumber: index + 1) {
                logItems.append(logItem)
                processedLines += 1
            } else {
                // 解析失败，创建纯文本日志项
                let logItem = LoganLogItem(
                    content: trimmedLine,
                    flag: "3",
                    logTime: Date().iso8601String,
                    threadName: "unknown",
                    threadId: "0",
                    isMainThread: "false"
                )
                logItems.append(logItem)
                processedLines += 1
                Logger.debug("行 \(index + 1) JSON解析失败，作为纯文本处理", category: Logger.parser)
            }
        }
        
        Logger.info("日志解析完成，处理行数: \(processedLines)，跳过空行: \(skippedLines)，总日志条数: \(logItems.count)", category: Logger.parser)
        
        return logItems
    }
    
    // 解析 JSON 日志行 - 使用正确的 Logan 字段映射
    private func parseJSONLogLine(_ line: String, lineNumber: Int) -> LoganLogItem? {
        // 预处理：移除可能的 BOM 和其他不可见字符
        let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\u{FEFF}", with: "") // 移除 BOM
        
        // 检查是否看起来像 JSON
        guard cleanLine.hasPrefix("{") && cleanLine.hasSuffix("}") else {
            return nil
        }
        
        guard let data = cleanLine.data(using: .utf8) else {
            Logger.info("行 \(lineNumber) 无法转换为 UTF-8 数据", category: Logger.parser)
            return nil
        }
        
        do {
            guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                Logger.debug("行 \(lineNumber) JSON 反序列化失败", category: Logger.parser)
                return nil
            }
            
            // 使用正确的 Logan JSON 字段映射 (c, l, f, n, i, m)
            let logItem = LoganLogItem(
                content: extractStringValue(from: jsonObject, key: LoganConstants.JsonFields.content),
                flag: extractStringValue(from: jsonObject, key: LoganConstants.JsonFields.flag, defaultValue: "3"),
                logTime: formatLogTime(jsonObject[LoganConstants.JsonFields.logTime]),
                threadName: extractStringValue(from: jsonObject, key: LoganConstants.JsonFields.threadName, defaultValue: "unknown"),
                threadId: extractStringValue(from: jsonObject, key: LoganConstants.JsonFields.threadId, defaultValue: "0"),
                isMainThread: extractStringValue(from: jsonObject, key: LoganConstants.JsonFields.isMainThread, defaultValue: "false")
            )
            
            return logItem
            
        } catch {
            Logger.debug("行 \(lineNumber) JSON 解析异常: \(error.localizedDescription)", category: Logger.parser)
            return nil
        }
    }
    
    // 安全提取字符串值的辅助方法
    private func extractStringValue(from dict: [String: Any], key: String, defaultValue: String = "") -> String {
        if let value = dict[key] as? String {
            return value
        } else if let value = dict[key] as? NSNumber {
            return value.stringValue
        } else if let value = dict[key] {
            return String(describing: value)
        } else {
            return defaultValue
        }
    }
    
    // 时间格式化 - Logan 使用毫秒时间戳
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
    
    // 更新进度
    @MainActor
    private func updateProgress(_ progress: Double) {
        parseProgress = progress
    }
}

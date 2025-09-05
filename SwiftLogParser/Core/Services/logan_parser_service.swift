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
        return decryptedData.removePKCS7Padding()
    }
    
    // AES/CBC 解密实现（使用 CommonCrypto）
    private func decryptAESCBC(data: Data, key: Data, iv: Data) throws -> Data {
        let cryptLength = size_t(data.count + kCCBlockSizeAES128)
        var cryptData = Data(count: cryptLength)
        
        let keyLength = size_t(kCCKeySizeAES128)
        let operation: CCOperation = UInt32(kCCDecrypt)
        let algorithm: CCAlgorithm = UInt32(kCCAlgorithmAES128)
        let options: CCOptions = 0 // NoPadding
        
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
    
    // 更新进度
    @MainActor
    private func updateProgress(_ progress: Double) {
        parseProgress = progress
    }
}

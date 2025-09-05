//
//  data+compression.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/5.
//

import Foundation
import Compression

extension Data {
    /// GZIP 解压缩 - 主入口
    func decompressGzip() throws -> Data {
        // 使用更完整的 GZIP 解析（支持多种格式）
        return try self.decompressGzipComplete()
    }
    
    /// 使用指定算法解压缩数据 - 改进版本
    func decompress(using algorithm: compression_algorithm) throws -> Data {
        return try self.withUnsafeBytes { bytes in
            let buffer = UnsafeBufferPointer<UInt8>(
                start: bytes.bindMemory(to: UInt8.self).baseAddress,
                count: count
            )
            
            // 使用更大的初始缓冲区，支持动态扩容
            var dstCapacity = Swift.max(4096, count * 8)
            var dstPtr = UnsafeMutablePointer<UInt8>.allocate(
                capacity: dstCapacity
            )
            defer { dstPtr.deallocate() }
            
            var decompressedSize = compression_decode_buffer(
                dstPtr, dstCapacity,
                buffer.baseAddress!, count,
                nil, algorithm
            )
            
            // 如果第一次失败，尝试更大的缓冲区
            if decompressedSize == 0 {
                dstPtr.deallocate()
                dstCapacity = count * 16  // 更大的缓冲区
                dstPtr = UnsafeMutablePointer<UInt8>.allocate(
                    capacity: dstCapacity
                )
                
                decompressedSize = compression_decode_buffer(
                    dstPtr, dstCapacity,
                    buffer.baseAddress!, count,
                    nil, algorithm
                )
            }
            
            // 如果还是失败，尝试最大缓冲区
            if decompressedSize == 0 {
                dstPtr.deallocate()
                dstCapacity = count * 32  // 最大缓冲区
                dstPtr = UnsafeMutablePointer<UInt8>.allocate(
                    capacity: dstCapacity
                )
                
                decompressedSize = compression_decode_buffer(
                    dstPtr, dstCapacity,
                    buffer.baseAddress!, count,
                    nil, algorithm
                )
            }
            
            guard decompressedSize > 0 else {
                throw LoganParseError.decompressionFailed
            }
            
            return Data(bytes: dstPtr, count: decompressedSize)
        }
    }
    
    /// 移除 PKCS7 填充
    func removePKCS7Padding() -> Data {
        guard !isEmpty else { return self }
        
        let paddingLength = Int(self[count - 1])
        
        // 验证填充
        guard paddingLength > 0 && paddingLength <= 16 &&
              paddingLength <= count else {
            return self
        }
        
        // 检查填充字节是否正确
        let paddingRange = (count - paddingLength)..<count
        let paddingBytes = self.subdata(in: paddingRange)
        
        for byte in paddingBytes {
            if byte != paddingLength {
                return self // 填充无效，返回原数据
            }
        }
        
        return self.prefix(count - paddingLength)
    }
    
    /// 添加 PKCS7 填充
    func addPKCS7Padding(blockSize: Int = 16) -> Data {
        let paddingLength = blockSize - (count % blockSize)
        var paddedData = self
        
        for _ in 0..<paddingLength {
            paddedData.append(UInt8(paddingLength))
        }
        
        return paddedData
    }
}

// MARK: - GZIP 解压缩实现 - 改进版本

extension Data {
    /// 更完整的 GZIP 解压缩实现 - 支持多种格式和容错
    func decompressGzipComplete() throws -> Data {
        // 长度校验
        guard count > 0 else {
            throw LoganParseError.decompressionFailed
        }
        
        // 记录调试信息
        let dataHex = self.prefix(Swift.min(16, count)).map { 
            String(format: "%02x", $0)
        }.joined(separator: " ")
        Logger.debug("解压缩数据头部: \(dataHex), 总长度: \(count)",
                    category: Logger.parser)

        // 尝试多种解压缩方式
        return try decompressWithMultipleStrategies()
    }
    
    /// 使用多种策略尝试解压缩
    private func decompressWithMultipleStrategies() throws -> Data {
        var lastError: Error?
        
        // 策略1: 检查是否为标准 GZIP 格式
        if count >= 10 && self[0] == 0x1f && self[1] == 0x8b {
            do {
                Logger.debug("尝试标准 GZIP 解压缩", category: Logger.parser)
                return try decompressStandardGzip()
            } catch {
                Logger.debug("标准 GZIP 解压缩失败: \(error)",
                           category: Logger.parser)
                lastError = error
            }
        }
        
        // 策略2: 尝试 zlib 格式（deflate with header）
        do {
            Logger.debug("尝试 ZLIB 解压缩", category: Logger.parser)
            return try decompressZlibImproved()
        } catch {
            Logger.debug("ZLIB 解压缩失败: \(error)", category: Logger.parser)
            lastError = error
        }
        
        // 策略3: 尝试原始 deflate 格式
        do {
            Logger.debug("尝试原始 DEFLATE 解压缩", category: Logger.parser)
            return try decompress(using: COMPRESSION_LZFSE)
        } catch {
            Logger.debug("DEFLATE 解压缩失败: \(error)", category: Logger.parser)
            lastError = error
        }
        
        // 策略4: 尝试 LZMA 格式
        do {
            Logger.debug("尝试 LZMA 解压缩", category: Logger.parser)
            return try decompress(using: COMPRESSION_LZMA)
        } catch {
            Logger.debug("LZMA 解压缩失败: \(error)", category: Logger.parser)
            lastError = error
        }
        
        // 策略5: 检查是否为未压缩的数据（直接返回）
        if isLikelyUncompressedText() {
            Logger.debug("数据似乎未压缩，直接返回", category: Logger.parser)
            return self
        }
        
        // 所有策略都失败
        Logger.error("所有解压缩策略都失败", category: Logger.parser)
        throw lastError ?? LoganParseError.decompressionFailed
    }
    
    /// 标准 GZIP 解压缩
    private func decompressStandardGzip() throws -> Data {
        // 仅支持 CM=8 (deflate)
        guard self[2] == 0x08 else {
            throw LoganParseError.decompressionFailed
        }

        var index = 10 // 固定头部长度
        let flg = self[3]

        // 解析可选字段
        index = try parseGzipOptionalFields(flg: flg, startIndex: index)

        // 数据区 [index, count-8)
        guard index < count - 8 else {
            throw LoganParseError.decompressionFailed
        }
        
        let payload = self.subdata(in: index..<(count - 8))
        Logger.debug("GZIP payload 大小: \(payload.count)",
                    category: Logger.parser)
        
        return try payload.decompress(using: COMPRESSION_ZLIB)
    }
    
    /// 解析 GZIP 可选字段
    private func parseGzipOptionalFields(flg: UInt8, startIndex: Int) throws -> Int {
        var index = startIndex
        
        // FEXTRA
        if (flg & 0x04) != 0 {
            guard index + 2 <= count else {
                throw LoganParseError.decompressionFailed
            }
            let xlen = Int(self[index]) | (Int(self[index + 1]) << 8)
            index += 2 + xlen
        }

        // FNAME (以 0 结尾)
        if (flg & 0x08) != 0 {
            while index < count && self[index] != 0 {
                index += 1
            }
            index += 1
        }

        // FCOMMENT (以 0 结尾)
        if (flg & 0x10) != 0 {
            while index < count && self[index] != 0 {
                index += 1
            }
            index += 1
        }

        // FHCRC
        if (flg & 0x02) != 0 {
            index += 2
        }
        
        return index
    }
    
    /// 改进的 zlib 解压缩
    private func decompressZlibImproved() throws -> Data {
        return try self.withUnsafeBytes { bytes in
            let srcPtr = bytes.bindMemory(to: UInt8.self).baseAddress!
            let srcSize = count

            // 使用更激进的缓冲区策略
            let multipliers = [8, 16, 32, 64, 128]
            
            for multiplier in multipliers {
                let dstCapacity = Swift.max(8192, srcSize * multiplier)
                let dstPtr = UnsafeMutablePointer<UInt8>.allocate(
                    capacity: dstCapacity
                )
                defer { dstPtr.deallocate() }

                let decompressedSize = compression_decode_buffer(
                    dstPtr, dstCapacity,
                    srcPtr, srcSize,
                    nil, COMPRESSION_ZLIB
                )

                if decompressedSize > 0 {
                    Logger.debug("ZLIB 解压缩成功，倍数: \(multiplier), 输出大小: \(decompressedSize)",
                               category: Logger.parser)
                    return Data(bytes: dstPtr, count: decompressedSize)
                }
            }

            throw LoganParseError.decompressionFailed
        }
    }
    
    /// 检查是否为未压缩的文本数据
    func isLikelyUncompressedText() -> Bool {
        guard count > 10 else { return false }
        
        // 检查前几个字节是否为可打印 ASCII 字符或 JSON 格式
        let sample = self.prefix(100)
        var printableCount = 0
        var jsonIndicators = 0
        
        for byte in sample {
            if (byte >= 0x20 && byte <= 0x7E) || byte == 0x09 ||
               byte == 0x0A || byte == 0x0D {
                printableCount += 1
            }
            
            if byte == 0x7B || byte == 0x7D || byte == 0x22 { // {, }, "
                jsonIndicators += 1
            }
        }
        
        let printableRatio = Double(printableCount) / Double(sample.count)
        return printableRatio > 0.8 || jsonIndicators > 2
    }
}

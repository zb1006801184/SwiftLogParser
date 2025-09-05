//
//  data+compression.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/5.
//

import Foundation
import Compression

extension Data {
    /// GZIP 解压缩
    func decompressGzip() throws -> Data {
        return try self.decompress(using: COMPRESSION_LZFSE)
    }
    
    /// 使用指定算法解压缩数据
    func decompress(using algorithm: compression_algorithm) throws -> Data {
        return try self.withUnsafeBytes { bytes in
            let buffer = UnsafeBufferPointer<UInt8>(
                start: bytes.bindMemory(to: UInt8.self).baseAddress,
                count: count
            )
            
            let destinationBuffer = UnsafeMutablePointer<UInt8>.allocate(
                capacity: count * 4
            )
            defer { destinationBuffer.deallocate() }
            
            let decompressedSize = compression_decode_buffer(
                destinationBuffer, count * 4,
                buffer.baseAddress!, count,
                nil, algorithm
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

// MARK: - GZIP 解压缩实现

extension Data {
    /// 更完整的 GZIP 解压缩实现
    func decompressGzipComplete() throws -> Data {
        // 检查 GZIP 头部
        guard count >= 10 else {
            throw LoganParseError.decompressionFailed
        }
        
        // GZIP 魔数检查
        guard self[0] == 0x1f && self[1] == 0x8b else {
            // 如果不是标准 GZIP 格式，尝试 zlib 解压
            return try decompressZlib()
        }
        
        return try self.withUnsafeBytes { bytes in
            let srcPtr = bytes.bindMemory(to: UInt8.self).baseAddress!
            let srcSize = count
            
            // 分配输出缓冲区
            let dstCapacity = srcSize * 4
            let dstPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: dstCapacity)
            defer { dstPtr.deallocate() }
            
            let decompressedSize = compression_decode_buffer(
                dstPtr, dstCapacity,
                srcPtr, srcSize,
                nil, COMPRESSION_LZFSE
            )
            
            guard decompressedSize > 0 else {
                throw LoganParseError.decompressionFailed
            }
            
            return Data(bytes: dstPtr, count: decompressedSize)
        }
    }
    
    /// zlib 解压缩
    private func decompressZlib() throws -> Data {
        return try self.withUnsafeBytes { bytes in
            let srcPtr = bytes.bindMemory(to: UInt8.self).baseAddress!
            let srcSize = count
            
            let dstCapacity = srcSize * 4
            let dstPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: dstCapacity)
            defer { dstPtr.deallocate() }
            
            let decompressedSize = compression_decode_buffer(
                dstPtr, dstCapacity,
                srcPtr, srcSize,
                nil, COMPRESSION_ZLIB
            )
            
            guard decompressedSize > 0 else {
                throw LoganParseError.decompressionFailed
            }
            
            return Data(bytes: dstPtr, count: decompressedSize)
        }
    }
}

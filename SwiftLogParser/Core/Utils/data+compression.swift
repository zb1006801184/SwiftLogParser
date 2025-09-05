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
        // 使用更完整的 GZIP 解析（支持 gzip/zlib）
        return try self.decompressGzipComplete()
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
        // 长度校验
        guard count > 0 else { throw LoganParseError.decompressionFailed }

        // 如果是 GZIP magic，则解析头部，提取 deflate 有效负载再解压
        if self.count >= 10 && self[0] == 0x1f && self[1] == 0x8b {
            // 仅支持 CM=8 (deflate)
            guard self[2] == 0x08 else { throw LoganParseError.decompressionFailed }

            var index = 10 // 固定头部长度
            let flg = self[3]

            // FEXTRA
            if (flg & 0x04) != 0 {
                guard index + 2 <= count else { throw LoganParseError.decompressionFailed }
                let xlen = Int(self[index]) | (Int(self[index + 1]) << 8)
                index += 2 + xlen
            }

            // FNAME (以 0 结尾)
            if (flg & 0x08) != 0 {
                while index < count && self[index] != 0 { index += 1 }
                index += 1
            }

            // FCOMMENT (以 0 结尾)
            if (flg & 0x10) != 0 {
                while index < count && self[index] != 0 { index += 1 }
                index += 1
            }

            // FHCRC
            if (flg & 0x02) != 0 {
                index += 2
            }

            // 数据区 [index, count-8)
            guard index < count - 8 else { throw LoganParseError.decompressionFailed }
            let payload = self.subdata(in: index..<(count - 8))
            return try payload.withUnsafeBytes { _ in
                // 使用 zlib 解码 deflate 数据
                return try payload.decompress(using: COMPRESSION_ZLIB)
            }
        } else {
            // 非 GZIP，则尝试按 zlib 流解压
            return try decompressZlib()
        }
    }
    
    /// zlib 解压缩
    private func decompressZlib() throws -> Data {
        return try self.withUnsafeBytes { bytes in
            let srcPtr = bytes.bindMemory(to: UInt8.self).baseAddress!
            let srcSize = count

            // 采用动态扩容策略，避免输出缓冲区不足
            var dstCapacity = Swift.max(1024, srcSize * 4)
            var dstPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: dstCapacity)
            defer { dstPtr.deallocate() }

            var decompressedSize = compression_decode_buffer(
                dstPtr, dstCapacity,
                srcPtr, srcSize,
                nil, COMPRESSION_ZLIB
            )

            if decompressedSize == 0 {
                // 尝试扩大缓冲区再解一次
                dstPtr.deallocate()
                dstCapacity = srcSize * 8
                dstPtr = UnsafeMutablePointer<UInt8>.allocate(capacity: dstCapacity)
                decompressedSize = compression_decode_buffer(
                    dstPtr, dstCapacity,
                    srcPtr, srcSize,
                    nil, COMPRESSION_ZLIB
                )
            }

            guard decompressedSize > 0 else {
                throw LoganParseError.decompressionFailed
            }

            return Data(bytes: dstPtr, count: decompressedSize)
        }
    }
}

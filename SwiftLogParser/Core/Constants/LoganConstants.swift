//
//  logan_constants.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/09/05.
//

import Foundation
import SwiftUI

// MARK: - Logan 解析常量
struct LoganConstants {
    // MARK: - 文件格式常量
    
    /// 加密内容开始标识符
    static let encryptContentStart: UInt8 = 0x01
    
    /// 文件头标识
    static let fileHeader: String = "logan"
    
    /// 默认 AES 密钥长度
    static let aesKeyLength: Int = 16
    
    /// 默认 IV 长度
    static let ivLength: Int = 16
    
    // MARK: - 默认密钥配置
    
    /// 默认 AES 密钥
    static let defaultAesKey = "0123456789012345"
    
    /// 默认 AES 向量
    static let defaultAesIv = "0123456789012345"
    
    // MARK: - JSON 字段映射
    
    /// Logan JSON 字段映射
    struct JsonFields {
        static let content = "c"        // 日志内容
        static let flag = "f"           // 日志类型标识
        static let logTime = "l"        // 日志时间
        static let threadName = "n"     // 线程名称
        static let threadId = "i"       // 线程ID
        static let isMainThread = "m"   // 是否主线程
    }
    
    // MARK: - 日志类型定义
    
    /// 日志类型枚举
    enum LogType: String, CaseIterable {
        case debug = "2"        // 调试信息
        case info = "3"         // 信息/埋点
        case error = "4"        // 错误信息
        case warning = "5"      // 警告信息
        case fatal = "6"        // 严重错误
        case network = "7"      // 网络请求
        case performance = "8"  // 性能指标
        
        /// 获取日志类型描述
        var description: String {
            switch self {
            case .debug: return "调试"
            case .info: return "信息"
            case .error: return "错误"
            case .warning: return "警告"
            case .fatal: return "严重"
            case .network: return "网络"
            case .performance: return "性能"
            }
        }
        
        /// 获取日志类型颜色
        var color: Color {
            switch self {
            case .debug: return .blue
            case .info: return .green
            case .error: return .red
            case .warning: return .orange
            case .fatal: return .purple
            case .network: return .cyan
            case .performance: return .yellow
            }
        }
    }
}

// MARK: - 全局日志类型映射

/// 日志类型描述映射
let logTypeMapping: [String: String] = [
    "2": "调试",
    "3": "信息",
    "4": "错误",
    "5": "警告",
    "6": "严重",
    "7": "网络",
    "8": "性能"
]

/// 日志类型颜色映射
let logTypeColors: [String: Color] = [
    "2": .blue,
    "3": .green,
    "4": .red,
    "5": .orange,
    "6": .purple,
    "7": .cyan,
    "8": .yellow
]

// MARK: - Logan 解析错误定义

/// Logan 解析错误枚举
enum LoganParseError: Error, LocalizedError {
    case fileNotFound
    case invalidFileFormat
    case decryptionFailed
    case decompressionFailed
    case jsonParseFailed
    case emptyResult
    case invalidKey
    case invalidIV
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "文件不存在"
        case .invalidFileFormat:
            return "无效的文件格式"
        case .decryptionFailed:
            return "解密失败，请检查密钥是否正确"
        case .decompressionFailed:
            return "解压缩失败，文件可能已损坏"
        case .jsonParseFailed:
            return "JSON 解析失败"
        case .emptyResult:
            return "解析结果为空，请检查文件内容"
        case .invalidKey:
            return "无效的 AES 密钥"
        case .invalidIV:
            return "无效的 AES IV"
        }
    }
}

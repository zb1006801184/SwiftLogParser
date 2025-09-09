//
//  LogType.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/8.
//

import Foundation
import SwiftUI

/// 日志类型枚举
/// 对应Logan日志系统中的flag字段
enum LogType: Int, CaseIterable, Identifiable {
    case header = 1       // 日志头
    case debug = 2        // 调试
    case info = 3         // 信息/埋点
    case error = 4        // 错误
    case warning = 5      // 警告
    case fatal = 6        // 严重错误/崩溃
    case network = 7      // 网络请求
    case performance = 8  // 性能指标
    
    var id: Int { rawValue }
    
    /// 日志类型的中文显示名称
    var displayName: String {
        switch self {
        case .header: return "日志头"
        case .debug: return "调试信息"
        case .info: return "信息/埋点"
        case .error: return "错误信息"
        case .warning: return "警告信息"
        case .fatal: return "严重错误"
        case .network: return "网络请求"
        case .performance: return "性能指标"
        }
    }
    
    /// 日志类型的详细描述
    var description: String {
        switch self {
        case .header: return "日志文件头信息"
        case .debug: return "调试信息"
        case .info: return "信息/埋点"
        case .error: return "错误日志"
        case .warning: return "警告信息"
        case .fatal: return "严重错误/崩溃"
        case .network: return "网络请求"
        case .performance: return "性能指标"
        }
    }
    
    /// 日志类型对应的颜色
    var color: Color {
        switch self {
        case .header: return .teal
        case .debug: return .gray
        case .info: return .blue
        case .error: return .red
        case .warning: return .orange
        case .fatal: return .purple
        case .network: return .green
        case .performance: return .cyan
        }
    }
    
    /// 日志类型对应的图标名称
    var iconName: String {
        switch self {
        case .header: return "doc.text.fill"
        case .debug: return "ant.fill"
        case .info: return "info.circle.fill"
        case .error: return "xmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .fatal: return "bolt.circle.fill"
        case .network: return "network"
        case .performance: return "speedometer"
        }
    }
    
    /// 从字符串值创建日志类型
    /// - Parameter stringValue: 字符串形式的flag值
    /// - Returns: 对应的日志类型，如果无法解析则返回nil
    static func from(stringValue: String) -> LogType? {
        guard let intValue = Int(stringValue) else { return nil }
        return LogType(rawValue: intValue)
    }
    
    /// 从整数值创建日志类型
    /// - Parameter intValue: 整数形式的flag值
    /// - Returns: 对应的日志类型，如果无法解析则返回nil
    static func from(intValue: Int) -> LogType? {
        return LogType(rawValue: intValue)
    }
}

/// 日志类型扩展 - 提供便捷方法
extension LogType {
    /// 是否为错误相关的日志类型
    var isError: Bool {
        switch self {
        case .error, .fatal:
            return true
        default:
            return false
        }
    }
    
    /// 是否为警告相关的日志类型
    var isWarning: Bool {
        return self == .warning
    }
    
    /// 是否为调试相关的日志类型
    var isDebug: Bool {
        return self == .debug
    }
    
    /// 日志优先级（数值越高优先级越高）
    var priority: Int {
        switch self {
        case .fatal: return 7
        case .error: return 6
        case .warning: return 5
        case .info: return 4
        case .network: return 3
        case .performance: return 2
        case .debug: return 1
        case .header: return 0
        }
    }
}

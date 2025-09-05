//
//  parse_history.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/5.
//

import Foundation
import SwiftUI

struct ParseHistory: Codable, Identifiable, Equatable {
    let id = UUID()
    
    // 文件路径
    let filePath: String
    
    // 文件名
    let fileName: String
    
    // 解析时间
    let parseTime: Date
    
    // 文件大小（字节）
    let fileSize: Int
    
    // 解析出的日志条数
    let logCount: Int
    
    // 解析是否成功
    let isSuccess: Bool
    
    // 错误信息（如果解析失败）
    let errorMessage: String?
    
    // 计算属性：格式化的文件大小
    var fileSizeFormatted: String {
        if fileSize < 1024 {
            return "\(fileSize)B"
        } else if fileSize < 1024 * 1024 {
            return String(format: "%.1fKB", Double(fileSize) / 1024.0)
        } else {
            return String(format: "%.1fMB", Double(fileSize) / (1024.0 * 1024.0))
        }
    }
    
    // 计算属性：格式化的解析时间
    var parseTimeFormatted: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: parseTime)
    }
    
    // 计算属性：状态描述
    var statusDescription: String {
        return isSuccess ? "解析成功" : "解析失败"
    }
    
    // 计算属性：状态颜色
    var statusColor: Color {
        return isSuccess ? .green : .red
    }
}
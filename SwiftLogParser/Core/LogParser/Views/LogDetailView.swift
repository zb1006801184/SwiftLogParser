//
//  LogDetailView.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/8.
//

import SwiftUI

/// 日志详情视图
struct LogDetailView: View {
    let logItem: LoganLogItem
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 日志时间信息
                timeSection
                
                // 日志类型信息
                typeSection
                
                // 日志内容
                contentSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
        }
        .background(Color(.controlBackgroundColor))
    }
    
    // MARK: - 视图组件
    
    /// 时间信息区域
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                
                Text("日志时间")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text(formattedDateTime)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    /// 类型信息区域
    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "tag")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                
                Text("日志类型")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text(logItem.logTypeDisplayName)
                .font(.body)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    /// 内容区域
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                
                Text("日志内容")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // 复制按钮
                Button("复制") {
                    copyToClipboard()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            Text(logItem.content)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding()
                .background(Color(.textBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(.separatorColor), lineWidth: 1)
                )
        }
    }
    
    // MARK: - 计算属性
    
    private var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.timeZone = TimeZone.current
        
        // 首先尝试解析 ISO8601 格式
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: logItem.logTime) {
            return formatter.string(from: date)
        }
        
        // 如果 ISO8601 解析失败，尝试解析为时间戳
        if let timeInterval = TimeInterval(logItem.logTime) {
            return formatter.string(from: Date(timeIntervalSince1970: timeInterval))
        }
        
        // 如果都解析失败，返回原始字符串
        return logItem.logTime
    }
    
    
    // MARK: - 私有方法
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(logItem.content, forType: .string)
    }
}

#Preview {
    LogDetailView(
        logItem: LoganLogItem(
            content: "[performance_monitor]: Current FPS: 120.88 ---Max Refresh Rate: 120.00",
            flag: "1",
            logTime: String(Date().timeIntervalSince1970),
            threadName: "main",
            threadId: "1",
            isMainThread: "true"
        )
    )
    .frame(width: 400, height: 600)
}

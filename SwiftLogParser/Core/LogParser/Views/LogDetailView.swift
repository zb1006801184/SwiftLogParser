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
            VStack(alignment: .leading, spacing: 16) {
                // 日志时间信息
                timeSection
                
                Divider()
                
                // 日志类型信息
                typeSection
                
                Divider()
                
                // 日志内容
                contentSection
            }
            .padding()
        }
        .background(Color(.controlBackgroundColor))
    }
    
    // MARK: - 视图组件
    
    /// 时间信息区域
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.blue)
                
                Text("日志时间")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text(formattedDateTime)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.textBackgroundColor))
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(.separatorColor), lineWidth: 1)
                )
        }
    }
    
    /// 类型信息区域
    private var typeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "tag")
                    .foregroundColor(.blue)
                
                Text("日志类型")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            HStack {
                Text(logTypeText)
                    .font(.body)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(logTypeColor)
                    .cornerRadius(6)
                
                Spacer()
            }
        }
    }
    
    /// 内容区域
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(.blue)
                
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
            
            ScrollView {
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
            .frame(minHeight: 200)
        }
    }
    
    // MARK: - 计算属性
    
    private var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        formatter.locale = Locale(identifier: "zh_CN")
        
        // 使用 logTime 属性而不是 timestamp
        if let timeInterval = TimeInterval(logItem.logTime) {
            return formatter.string(from: Date(timeIntervalSince1970: timeInterval))
        } else {
            // 如果无法解析时间戳，直接返回原始时间字符串
            return logItem.logTime
        }
    }
    
    private var logTypeText: String {
        let content = logItem.content.lowercased()
        if content.contains("performance") || content.contains("fps") || content.contains("memory") {
            return "性能指标"
        } else if content.contains("error") {
            return "错误日志"
        } else if content.contains("warning") || content.contains("warn") {
            return "警告日志"
        } else {
            return "信息日志"
        }
    }
    
    private var logTypeColor: Color {
        let content = logItem.content.lowercased()
        if content.contains("performance") || content.contains("fps") || content.contains("memory") {
            return .orange
        } else if content.contains("error") {
            return .red
        } else if content.contains("warning") || content.contains("warn") {
            return .yellow
        } else {
            return .blue
        }
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

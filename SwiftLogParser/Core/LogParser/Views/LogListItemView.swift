//
//  LogListItemView.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/8.
//

import SwiftUI

/// 日志列表项视图
struct LogListItemView: View {
    let logItem: LoganLogItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // 顶部信息行
                HStack {
                    // 时间戳
                    Text(formattedTime)
                        .font(.system(size: 11).monospaced())
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    
                    Spacer()
                    
                    // 日志类型标签
                    Text(logTypeText)
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(logTypeColor)
                        .cornerRadius(4)
                }
                
                // 日志内容
                Text(logItem.content)
                    .font(.system(size: 13).monospaced())
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.leading)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                Rectangle()
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                    .overlay(
                        Rectangle()
                            .stroke(
                                isSelected ? Color.accentColor : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 计算属性
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        
        // 尝试解析 logTime 字符串，如果失败则使用当前时间
        if let timeInterval = Double(logItem.logTime) {
            return formatter.string(from: Date(timeIntervalSince1970: timeInterval))
        } else {
            // 如果 logTime 已经是格式化的字符串，直接返回
            return logItem.logTime
        }
    }
    
    private var logTypeText: String {
        let content = logItem.content.lowercased()
        if content.contains("performance") || content.contains("fps") {
            return "性能指标"
        } else if content.contains("error") {
            return "错误"
        } else if content.contains("warning") || content.contains("warn") {
            return "警告"
        } else {
            return "信息"
        }
    }
    
    private var logTypeColor: Color {
        let content = logItem.content.lowercased()
        if content.contains("performance") || content.contains("fps") {
            return .orange
        } else if content.contains("error") {
            return .red
        } else if content.contains("warning") || content.contains("warn") {
            return .yellow
        } else {
            return .blue
        }
    }
}

#Preview {
    VStack {
        LogListItemView(
            logItem: LoganLogItem(
                content: "[performance_monitor]: Current FPS: 120.88 ---Max Refresh Rate: 120.00",
                flag: "1",
                logTime: "\(Date().timeIntervalSince1970)",
                threadName: "main",
                threadId: "1",
                isMainThread: "true"
            ),
            isSelected: true,
            onTap: {}
        )
        
        LogListItemView(
            logItem: LoganLogItem(
                content: "[error]: Failed to load resource",
                flag: "3",
                logTime: "\(Date().timeIntervalSince1970)",
                threadName: "background",
                threadId: "2",
                isMainThread: "false"
            ),
            isSelected: false,
            onTap: {}
        )
    }
    .padding()
}

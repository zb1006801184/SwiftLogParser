//
//  LogListItemView.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/8.
//

import SwiftUI

/// 日志列表项视图
/// 显示单个日志条目的简要信息，包含类型标识
struct LogListItemView: View {
    let logItem: LoganLogItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 时间戳 - 顶部显示
            Text(formatTime(logItem.logTime))
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 日志内容
            Text(logItem.content.isEmpty ? "<空内容>" : logItem.content)
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .lineLimit(2)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 底部标签区域
            HStack {
                Spacer()
                
                // 日志类型标签
                HStack(spacing: 4) {
                    Image(systemName: logItem.logTypeIconName)
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                    
                    Text(logItem.logTypeDisplayName)
                        .font(.caption2)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(logItem.logTypeColor)
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isSelected ? Color.accentColor : Color.clear,
                            lineWidth: isSelected ? 2 : 0
                        )
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
    
    /// 格式化时间显示
    private func formatTime(_ timeString: String) -> String {
        // 尝试解析ISO8601格式的时间
        let iso8601Formatter = ISO8601DateFormatter()
        if let date = iso8601Formatter.date(from: timeString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            return displayFormatter.string(from: date)
        }
        
        // 如果ISO8601解析失败，尝试解析为时间戳
        if let timeInterval = TimeInterval(timeString) {
            let date = Date(timeIntervalSince1970: timeInterval)
            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            return displayFormatter.string(from: date)
        }
        
        // 如果都解析失败，返回原始字符串
        return timeString
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

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
        HStack(spacing: 12) {
            // 日志类型图标和颜色标识
            VStack(spacing: 4) {
                Image(systemName: logItem.logTypeIconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(logItem.logTypeColor)
                
                Text(logItem.logTypeDisplayName)
                    .font(.caption2)
                    .foregroundColor(logItem.logTypeColor)
                    .lineLimit(1)
            }
            .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                // 日志内容预览 - 为空给出占位
                let preview = logItem.content.isEmpty ? "<空内容>" : logItem.content
                Text(preview)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .truncationMode(.tail)
                
                // 日志详细信息
                HStack(spacing: 8) {
                    // 时间信息
                    Text(formatTime(logItem.logTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // 线程信息
                    if !logItem.threadName.isEmpty &&
                       logItem.threadName != "unknown" {
                        Text("线程: \(logItem.threadName)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.secondary.opacity(0.1))
                            )
                    }
                    
                    // 主线程标识
                    if logItem.isMainThread == "true" {
                        Text("主线程")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue)
                            )
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ?
                      Color.accentColor.opacity(0.1) :
                      Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            isSelected ?
                            Color.accentColor :
                            Color.clear,
                            lineWidth: 1
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
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: timeString) else {
            return timeString
        }
        
        // 格式化为本地时间显示
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MM-dd HH:mm:ss.SSS"
        return displayFormatter.string(from: date)
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

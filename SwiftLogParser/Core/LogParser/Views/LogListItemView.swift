//
//  LogListItemView.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/8.
//

import SwiftUI
import SwiftUIX

/// 日志列表项视图 - 现代化设计
/// 显示单个日志条目的简要信息，包含类型标识和现代化样式
struct LogListItemView: View {
    let logItem: LoganLogItem
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // 顶部：时间戳和类型标签横向对齐
            HStack {
                // 时间戳 - 使用等宽字体
                Text(formatTime(logItem.logTime))
                    .font(DesignSystem.Typography.codeSmall.weight(.medium))
                    .foregroundColor(DesignSystem.Colors.primary)
                
                Spacer()
                
                // 日志类型标签 - 现代化设计
                HStack(spacing: DesignSystem.Spacing.xs) {
                    Image(systemName: logItem.logTypeIconName)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(logItem.logTypeDisplayName)
                        .font(DesignSystem.Typography.caption2.weight(.medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, DesignSystem.Spacing.sm)
                .padding(.vertical, DesignSystem.Spacing.xs)
                .background(
                    Capsule()
                        .fill(logItem.logTypeColor)
                        .shadowSmall()
                )
            }
            
            // 日志内容 - 改进的文本显示
            Text(logItem.content.isEmpty ? "<空内容>" : logItem.content)
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .lineLimit(3)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
                .multilineTextAlignment(.leading)
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(backgroundFill)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .shadowMedium()
        )
        .scaleEffect(isSelected ? 1.02 : (isHovered ? 1.01 : 1.0))
        .animation(DesignSystem.Animation.spring, value: isSelected)
        .animation(DesignSystem.Animation.quick, value: isHovered)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    
    // MARK: - 计算属性
    
    /// 背景填充色
    private var backgroundFill: Color {
        if isSelected {
            return DesignSystem.Colors.primaryLight
        } else if isHovered {
            return DesignSystem.Colors.surfaceElevated
        } else {
            return DesignSystem.Colors.surface
        }
    }
    
    /// 边框颜色
    private var borderColor: Color {
        if isSelected {
            return DesignSystem.Colors.primary
        } else if isHovered {
            return DesignSystem.Colors.borderFocus
        } else {
            return DesignSystem.Colors.borderLight
        }
    }
    
    /// 边框宽度
    private var borderWidth: CGFloat {
        return isSelected ? 2 : 1
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

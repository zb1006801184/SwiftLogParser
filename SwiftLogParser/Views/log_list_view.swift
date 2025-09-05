//
//  log_list_view.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/5.
//

import SwiftUI

struct LogListView: View {
    @ObservedObject var viewModel: MainViewModel
    @Binding var selectedLogItem: LoganLogItem?
    
    var body: some View {
        VStack(spacing: 0) {
            // 列表头部
            LogListHeader(viewModel: viewModel)
            
            Divider()
            
            // 日志列表
            if viewModel.filteredLogItems.isEmpty {
                EmptyStateView(
                    icon: "doc.text.magnifyingglass",
                    title: viewModel.logItems.isEmpty ? "未解析日志文件" : "未找到匹配的日志",
                    subtitle: viewModel.logItems.isEmpty ? "请选择 Logan 日志文件进行解析" : "尝试调整搜索条件或筛选类型"
                )
            } else {
                List(viewModel.filteredLogItems, selection: $selectedLogItem) { logItem in
                    LogItemRow(logItem: logItem)
                        .tag(logItem)
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle("日志列表")
    }
}

// 列表头部
struct LogListHeader: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        HStack {
            Text("日志条目")
                .font(.headline)
            
            Spacer()
            
            if !viewModel.filteredLogItems.isEmpty {
                Text("显示 \(viewModel.filteredLogItems.count) / \(viewModel.logItems.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// 日志项行
struct LogItemRow: View {
    let logItem: LoganLogItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // 第一行：时间和日志类型
            HStack {
                Text(logItem.formattedLogTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospaced()
                
                Spacer()
                
                LogTypeTag(
                    type: logItem.logTypeDescription,
                    color: logItem.logTypeColor
                )
            }
            
            // 第二行：日志内容
            Text(logItem.content ?? "无内容")
                .font(.body)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // 第三行：线程信息
            HStack {
                Label(logItem.threadName ?? "unknown", systemImage: "cpu")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if logItem.isMainThread == "true" {
                    Label("主线程", systemImage: "star.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

// 日志类型标签
struct LogTypeTag: View {
    let type: String
    let color: Color
    
    var body: some View {
        Text(type)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

// 空状态视图
struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    LogListView(
        viewModel: MainViewModel(),
        selectedLogItem: .constant(nil)
    )
    .frame(width: 400, height: 600)
}

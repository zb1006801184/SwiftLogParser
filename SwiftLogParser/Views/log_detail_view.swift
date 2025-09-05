//
//  log_detail_view.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/5.
//

import SwiftUI

struct LogDetailView: View {
    let logItem: LoganLogItem?
    
    var body: some View {
        Group {
            if let logItem = logItem {
                LogDetailContent(logItem: logItem)
            } else {
                EmptyDetailView()
            }
        }
        .navigationTitle("日志详情")
    }
}

// 日志详情内容
struct LogDetailContent: View {
    let logItem: LoganLogItem
    @State private var showRawData = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 基本信息
                LogDetailSection(title: "基本信息") {
                    LogDetailItem(label: "时间", value: logItem.formattedLogTime)
                    LogDetailItem(label: "类型", value: logItem.logTypeDescription) {
                        LogTypeTag(
                            type: logItem.logTypeDescription,
                            color: logItem.logTypeColor
                        )
                    }
                    LogDetailItem(label: "线程", value: logItem.threadName ?? "未知")
                    LogDetailItem(label: "线程ID", value: logItem.threadId ?? "未知")
                    LogDetailItem(label: "主线程", value: logItem.isMainThread == "true" ? "是" : "否")
                }
                
                // 日志内容
                LogDetailSection(title: "日志内容") {
                    Text(logItem.content ?? "无内容")
                        .font(.body)
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                        )
                }
                
                // 原始数据
                LogDetailSection(title: "原始数据") {
                    DisclosureGroup("查看 JSON 数据", isExpanded: $showRawData) {
                        if let jsonData = try? JSONEncoder().encode(logItem),
                           let jsonString = String(data: jsonData, encoding: .utf8) {
                            Text(jsonString)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(8)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

// 日志详情区域
struct LogDetailSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// 日志详情项
struct LogDetailItem<Accessory: View>: View {
    let label: String
    let value: String
    let accessory: Accessory?
    
    init(label: String, value: String) where Accessory == EmptyView {
        self.label = label
        self.value = value
        self.accessory = nil
    }
    
    init(label: String, value: String, @ViewBuilder accessory: () -> Accessory) {
        self.label = label
        self.value = value
        self.accessory = accessory()
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            if let accessory = accessory {
                accessory
            } else {
                Text(value)
                    .font(.body)
                    .textSelection(.enabled)
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
}

// 空详情视图
struct EmptyDetailView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.below.ecg")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("请选择日志条目")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("从左侧列表中选择一条日志来查看详细信息")
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
    LogDetailView(logItem: LoganLogItem(
        content: "这是一条示例日志内容",
        flag: "4",
        logTime: "1693900800000",
        threadName: "main",
        threadId: "1",
        isMainThread: "true"
    ))
    .frame(width: 400, height: 600)
}

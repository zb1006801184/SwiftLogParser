//
//  HistoryView.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/8.
//

import SwiftUI

/// 解析历史页面
struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部标题栏
            headerView
            
            // 历史记录内容
            if viewModel.hasHistories {
                historyListView
            } else {
                emptyStateView
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .onAppear {
            viewModel.loadHistories()
        }
        .alert("清空历史记录", isPresented: $viewModel.showingClearAlert) {
            Button("取消", role: .cancel) { }
            Button("清空", role: .destructive) {
                viewModel.clearAllHistories()
            }
        } message: {
            Text("确定要清空所有解析历史记录吗？此操作不可撤销。")
        }
    }
    
    // MARK: - 顶部标题栏
    private var headerView: some View {
        HStack {
            // 标题图标和文字
            HStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("解析历史记录")
                    .font(.title2)
                    .fontWeight(.medium)
            }
            
            Spacer()
            
            // 清空历史按钮
            if viewModel.hasHistories {
                Button(action: {
                    viewModel.showClearAlert()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "minus.circle")
                        Text("清空历史")
                    }
                    .foregroundColor(.red)
                    .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.red.opacity(0.1))
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - 历史记录列表
    private var historyListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.histories) { history in
                    HistoryItemView(
                        history: history,
                        onDelete: {
                            viewModel.deleteHistory(id: history.id)
                        }
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
    }
    
    // MARK: - 空状态视图
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("暂无解析历史")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("当您解析日志文件后，历史记录将显示在这里")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - 历史记录条目视图
struct HistoryItemView: View {
    let history: ParseHistory
    let onDelete: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部信息栏
            HStack {
                // 解析状态指示器
                HStack(spacing: 6) {
                    Image(systemName: history.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(history.isSuccess ? .green : .red)
                    
                    Text(history.isSuccess ? "解析成功" : "解析失败")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(history.isSuccess ? .green : .red)
                }
                
                Spacer()
                
                // 解析时间
                Text(history.formattedParseDate)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                
                // 删除按钮
                if isHovered {
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .padding(6)
                    .background(
                        Circle()
                            .fill(Color.red.opacity(0.1))
                    )
                }
            }
            
            // 文件名
            HStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                
                Text(history.fileName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
            }
            
            // 文件统计信息
            HStack(spacing: 20) {
                // 文件大小
                HStack(spacing: 4) {
                    Image(systemName: "doc")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(history.formattedFileSize)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                // 日志条数
                HStack(spacing: 4) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text("\(history.logCount)条日志")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // 文件路径
            HStack(spacing: 6) {
                Image(systemName: "folder")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                Text(history.filePath)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            // 错误信息（如果有）
            if !history.isSuccess, let errorMessage = history.errorMessage {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                    
                    Text(errorMessage)
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                        .lineLimit(2)
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
                .shadow(
                    color: .black.opacity(isHovered ? 0.15 : 0.08),
                    radius: isHovered ? 8 : 4,
                    x: 0,
                    y: isHovered ? 4 : 2
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    history.isSuccess ? Color.green.opacity(0.3) : Color.red.opacity(0.3),
                    lineWidth: history.isSuccess ? 1 : 1.5
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

#if DEBUG
struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
            .frame(width: 800, height: 600)
    }
}
#endif
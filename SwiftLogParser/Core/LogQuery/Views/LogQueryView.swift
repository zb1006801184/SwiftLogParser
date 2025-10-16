//
//  LogQueryView.swift
//  SwiftLogParser
//
//  Created by AI Assistant on 2025/10/15.
//

import SwiftUI

#if canImport(Moya)

/// 日志查询主视图
struct LogQueryView: View {
    @StateObject private var viewModel = LogQueryViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // 顶部查询栏
            queryBar
            
            Divider()
            
            // 文件列表区域
            fileListSection
        }
        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定", role: .cancel) {
                viewModel.showError = false
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .alert("已复制", isPresented: $viewModel.showCopySuccess) {
            Button("确定", role: .cancel) {
                viewModel.showCopySuccess = false
            }
        } message: {
            Text("文件地址已复制到剪贴板")
        }
    }
    
    // MARK: - 顶部查询栏
    
    private var queryBar: some View {
        HStack(spacing: 12) {
            // 用户ID输入
            Text("用户ID:")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            TextField("请输入用户ID", text: $viewModel.userId)
                .textFieldStyle(.roundedBorder)
                .frame(width: 150)
            
            Divider()
                .frame(height: 24)
            
            // 时间范围选择
            Text("时间范围:")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            DatePicker(
                "开始时间",
                selection: $viewModel.startTime,
                displayedComponents: [.date]
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            
            Text("至")
                .foregroundColor(.secondary)
            
            DatePicker(
                "结束时间",
                selection: $viewModel.endTime,
                displayedComponents: [.date]
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            
            Divider()
                .frame(height: 24)
            
            // 获取按钮
            Button(action: {
                viewModel.fetchLogFiles()
            }) {
                HStack(spacing: 6) {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.7)
                            .frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                            .frame(width: 16, height: 16)
                    }
                    Text("获取")
                }
                .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue)
            .cornerRadius(6)
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading || viewModel.userId.isEmpty)
            
            Spacer()
        }
        .padding(16)
        .background(Color(.controlBackgroundColor))
    }
    
    // MARK: - 文件列表区域
    
    private var fileListSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 列表标题
            HStack {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(.blue)
                Text("文件列表")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !viewModel.fileItems.isEmpty {
                    Text("\(viewModel.fileItems.count) 个文件")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("·")
                        .foregroundColor(.secondary)
                    
                    Text("点击条目复制地址")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.windowBackgroundColor))
            
            Divider()
            
            // 文件列表
            if viewModel.isLoading {
                // 加载中显示加载提示
                loadingStateView
            } else if viewModel.fileItems.isEmpty {
                emptyFileListView
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(viewModel.fileItems.enumerated()), id: \.element.id) { index, item in
                            FileItemRow(
                                fileItem: item,
                                isSelected: false,
                                onTap: {
                                    viewModel.copyFileUrl(item.url)
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.controlBackgroundColor))
    }
    
    // MARK: - 加载中状态视图
    
    private var loadingStateView: some View {
        VStack(spacing: 20) {
            // 加载动画
            VStack(spacing: 12) {
                ZStack {
                    // 外层旋转圆环
                    Circle()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 3)
                        .frame(width: 60, height: 60)
                    
                    // 内层旋转圆环
                    Circle()
                        .trim(from: 0, to: 0.75)
                        .stroke(Color.blue, lineWidth: 3)
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(loadingRotation))
                        .animation(
                            .linear(duration: 1.0)
                            .repeatForever(autoreverses: false),
                            value: loadingRotation
                        )
                }
                
                Text("正在查询日志文件...")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .onAppear {
                loadingRotation = 360
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    @State private var loadingRotation: Double = 0

    private var emptyFileListView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("请输入ID并点击获取")
                .font(.body)
                .foregroundColor(.secondary)
            
            Text("获取文件列表后，点击任意条目可复制下载地址")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 文件项行视图

struct FileItemRow: View {
    let fileItem: LogFileItem
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "doc.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                
                Text(fileItem.fileName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Spacer()
                
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .opacity(isHovered ? 1 : 0)
            }
            
            Text(fileItem.url)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(2)
                .truncationMode(.middle)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(borderColor, lineWidth: 1)
                )
        )
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isHovered)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var backgroundFill: Color {
        if isHovered {
            return Color.blue.opacity(0.1)
        } else {
            return Color(.controlBackgroundColor)
        }
    }
    
    private var borderColor: Color {
        if isHovered {
            return Color.blue.opacity(0.3)
        } else {
            return Color.gray.opacity(0.2)
        }
    }
}

#Preview {
    LogQueryView()
        .frame(width: 600, height: 400)
}

#endif

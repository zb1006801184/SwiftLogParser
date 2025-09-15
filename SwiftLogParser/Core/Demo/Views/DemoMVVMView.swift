//
//  DemoMVVMView.swift
//  SwiftLogParser
//
//  Created by AI on 2025/9/15.
//

import SwiftUI

/// 基于视图模型的简易演示界面
/// 展示如何使用 `DemoViewModel` 进行数据加载与展示
public struct DemoMVVMView: View {
    @StateObject private var viewModel = DemoViewModel()

    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            _buildHeader()
            _buildActions()
            _buildContent()
        }
        .padding()
        .navigationTitle("演示(MVVM)")
        .task {
            // 首次进入自动加载用户
            await viewModel.loadMockUsers()
        }
    }
}

// MARK: - 视图构建

private extension DemoMVVMView {
    /// 顶部标题
    func _buildHeader() -> some View {
        VStack(spacing: 8) {
            Text("MVVM 演示")
                .font(.title)
                .fontWeight(.bold)
            Text("使用 DemoViewModel 加载与展示数据")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 操作按钮区
    func _buildActions() -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button("加载用户") {
                    Task { await viewModel.loadMockUsers() }
                }
                .buttonStyle(.borderedProminent)

                Button("加载日志") {
                    Task { await viewModel.loadMockLogs() }
                }
                .buttonStyle(.bordered)

                Button("清空") {
                    viewModel.clearData()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// 内容区（加载/错误/标签）
    func _buildContent() -> some View {
        Group {
            if viewModel.isLoading {
                _buildLoadingView()
            } else if let msg = viewModel.errorMessage {
                _buildErrorView(msg)
            } else {
                _buildTabs()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// 加载视图
    func _buildLoadingView() -> some View {
        VStack(spacing: 12) {
            ProgressView().scaleEffect(1.3)
            Text("正在加载...")
                .foregroundColor(.secondary)
        }
    }

    /// 错误视图
    func _buildErrorView(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.red)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button("重试") {
                Task { await viewModel.loadMockUsers() }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    /// 标签页（用户/日志）
    func _buildTabs() -> some View {
        TabView(selection: $viewModel.selectedTab) {
            _buildUsersList()
                .tabItem {
                    Image(systemName: "person.2")
                    Text("用户")
                }
                .tag(0)

            _buildLogsList()
                .tabItem {
                    Image(systemName: "doc.text")
                    Text("日志")
                }
                .tag(1)
        }
        .frame(height: 380)
    }

    /// 用户列表
    func _buildUsersList() -> some View {
        List(viewModel.users) { user in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(user.name).font(.headline)
                    Spacer()
                    Text(user.id)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .listStyle(.inset)
    }

    /// 日志列表
    func _buildLogsList() -> some View {
        List(viewModel.logs) { log in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(log.level.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color(log.level.color).opacity(0.2))
                        .foregroundColor(Color(log.level.color))
                        .cornerRadius(4)
                    Spacer()
                    Text(log.timestamp, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(log.message)
                Text("来源: \(log.source)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .listStyle(.inset)
    }
}

// MARK: - 预览

#Preview {
    NavigationView { DemoMVVMView() }
}



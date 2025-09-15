//
//  DemoView.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/15.
//

import SwiftUI

/// 演示视图：展示如何使用 DemoService 进行网络请求
public struct DemoView: View {
    @State private var users: [DemoUser] = []
    @State private var logs: [DemoLog] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let demoService = DemoService()
    
    public var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题
                Text("演示功能")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // 操作按钮区域
                _buildActionButtons()
                
                // 内容区域
                if isLoading {
                    _buildLoadingView()
                } else if let errorMessage = errorMessage {
                    _buildErrorView(errorMessage)
                } else {
                    _buildContentTabs()
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("演示")
//            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - 私有构建方法
    
    /// 构建操作按钮区域
    private func _buildActionButtons() -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button("加载模拟用户") {
                    loadMockUsers()
                }
                .buttonStyle(.borderedProminent)
                
                Button("加载模拟日志") {
                    loadMockLogs()
                }
                .buttonStyle(.bordered)
            }
            
            HStack(spacing: 12) {
                Button("清空数据") {
                    clearData()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                
                Button("模拟网络请求") {
                    simulateNetworkRequest()
                }
                .buttonStyle(.bordered)
                .foregroundColor(.blue)
            }
        }
    }
    
    /// 构建加载视图
    private func _buildLoadingView() -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在加载...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// 构建错误视图
    private func _buildErrorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.red)
            
            Text("出现错误")
                .font(.headline)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("重试") {
                errorMessage = nil
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// 构建内容标签页
    private func _buildContentTabs() -> some View {
        TabView {
            // 用户列表
            _buildUsersList()
                .tabItem {
                    Image(systemName: "person.2")
                    Text("用户")
                }
            
            // 日志列表
            _buildLogsList()
                .tabItem {
                    Image(systemName: "doc.text")
                    Text("日志")
                }
        }
        .frame(height: 400)
    }
    
    /// 构建用户列表
    private func _buildUsersList() -> some View {
        List(users) { user in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(user.name)
                        .font(.headline)
                    Spacer()
                    Text(user.id)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let avatar = user.avatar {
                    Text("头像: \(avatar)")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    /// 构建日志列表
    private func _buildLogsList() -> some View {
        List(logs) { log in
            VStack(alignment: .leading, spacing: 8) {
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
                    .font(.body)
                
                Text("来源: \(log.source)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - 私有方法

private extension DemoView {
    
    /// 加载模拟用户数据
    func loadMockUsers() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.users = self.demoService.generateMockUsers()
            self.isLoading = false
        }
    }
    
    /// 加载模拟日志数据
    func loadMockLogs() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.logs = self.demoService.generateMockLogs()
            self.isLoading = false
        }
    }
    
    /// 清空数据
    func clearData() {
        users.removeAll()
        logs.removeAll()
        errorMessage = nil
    }
    
    /// 模拟网络请求
    func simulateNetworkRequest() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // 模拟网络请求失败
            self.errorMessage = "网络请求失败：连接超时"
            self.isLoading = false
        }
    }
}

// MARK: - 预览

#Preview {
    DemoView()
}

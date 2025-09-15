//
//  DemoViewModel.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/15.
//

import Foundation
import SwiftUI

/// 演示视图模型：管理演示功能的状态和业务逻辑
@MainActor
public final class DemoViewModel: ObservableObject {
    
    // MARK: - 发布属性
    
    @Published var users: [DemoUser] = []
    @Published var logs: [DemoLog] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedTab = 0
    
    // MARK: - 私有属性
    
    private let demoService = DemoService()
    
    // MARK: - 公共方法
    
    /// 加载模拟用户数据
    func loadMockUsers() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 模拟网络延迟
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
            
            let mockUsers = demoService.generateMockUsers()
            users = mockUsers
            isLoading = false
        } catch {
            errorMessage = "加载用户数据失败: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    /// 加载模拟日志数据
    func loadMockLogs() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 模拟网络延迟
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒
            
            let mockLogs = demoService.generateMockLogs()
            logs = mockLogs
            isLoading = false
        } catch {
            errorMessage = "加载日志数据失败: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    /// 清空所有数据
    func clearData() {
        users.removeAll()
        logs.removeAll()
        errorMessage = nil
    }
    
    /// 模拟网络请求
    func simulateNetworkRequest() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // 模拟网络延迟
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2秒
            
            // 随机决定成功或失败
            if Bool.random() {
                // 模拟成功
                users = demoService.generateMockUsers()
                logs = demoService.generateMockLogs()
            } else {
                // 模拟失败
                errorMessage = "网络请求失败：连接超时"
            }
            
            isLoading = false
        } catch {
            errorMessage = "网络请求异常: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    /// 搜索用户
    func searchUsers(query: String) {
        guard !query.isEmpty else {
            users = demoService.generateMockUsers()
            return
        }
        
        let allUsers = demoService.generateMockUsers()
        users = allUsers.filter { user in
            user.name.localizedCaseInsensitiveContains(query) ||
            user.email.localizedCaseInsensitiveContains(query)
        }
    }
    
    /// 按日志级别过滤日志
    func filterLogs(by level: LogLevel?) {
        let allLogs = demoService.generateMockLogs()
        
        if let level = level {
            logs = allLogs.filter { $0.level == level }
        } else {
            logs = allLogs
        }
    }
    
    /// 获取日志统计信息
    func getLogStatistics() -> [LogLevel: Int] {
        var statistics: [LogLevel: Int] = [:]
        
        for level in LogLevel.allCases {
            statistics[level] = logs.filter { $0.level == level }.count
        }
        
        return statistics
    }
}

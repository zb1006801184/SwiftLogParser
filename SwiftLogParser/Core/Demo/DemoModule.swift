//
//  DemoModule.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/15.
//

import Foundation
import SwiftUI

/// 演示模块入口文件
/// 提供演示功能的统一访问接口
public struct DemoModule {
    
    /// 获取演示视图
    /// - Returns: 演示视图实例
    public static func createDemoView() -> some View {
       return DemoView()
    }
    
    /// 获取演示视图模型
    /// - Returns: 演示视图模型实例
    @MainActor
    public static func createDemoViewModel() -> DemoViewModel {
      return  DemoViewModel()
    }
    
    /// 获取演示服务
    /// - Returns: 演示服务实例
    public static func createDemoService() -> DemoService {
        DemoService()
    }
    
    /// 获取演示数据模型示例
    /// - Returns: 演示用户和日志数据
    public static func getDemoData() -> (users: [DemoUser], logs: [DemoLog]) {
        let service = DemoService()
        return (
            users: service.generateMockUsers(),
            logs: service.generateMockLogs()
        )
    }
}

// MARK: - 使用示例

/*
 使用方法：
 
 1. 在视图中使用演示功能：
    struct MyView: View {
        var body: some View {
            DemoModule.createDemoView()
        }
    }
 
 2. 在视图模型中使用：
    class MyViewModel: ObservableObject {
        private let demoService = DemoModule.createDemoService()
        
        func loadData() {
            // 使用演示服务
        }
    }
 
 3. 获取演示数据：
    let (users, logs) = DemoModule.getDemoData()
 */

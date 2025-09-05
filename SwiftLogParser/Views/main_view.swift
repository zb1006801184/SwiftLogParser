//
//  main_view.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/5.
//

import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = MainViewModel()
    @State private var showSettings = false
    @State private var selectedLogItem: LoganLogItem?
    
    var body: some View {
        NavigationSplitView {
            // 左侧边栏
            SidebarView(viewModel: viewModel, showSettings: $showSettings)
                .frame(minWidth: 300)
        } content: {
            // 中间日志列表
            LogListView(
                viewModel: viewModel,
                selectedLogItem: $selectedLogItem
            )
            .frame(minWidth: 400)
        } detail: {
            // 右侧详情
            LogDetailView(logItem: selectedLogItem)
                .frame(minWidth: 400)
        }
        .navigationTitle("Logan 日志解析工具")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button("选择文件") {
                    viewModel.selectAndParseFile()
                }
                .disabled(viewModel.isLoading)
                
                Button("导出文本") {
                    viewModel.exportAsText()
                }
                .disabled(viewModel.logItems.isEmpty)
                
                Button("清空") {
                    viewModel.clearLogs()
                }
                .disabled(viewModel.logItems.isEmpty)
                
                Button("设置") {
                    showSettings = true
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(settingsService: viewModel.getSettingsService())
        }
        .alert("错误", isPresented: $viewModel.showError) {
            Button("确定") { }
        } message: {
            Text(viewModel.errorMessage ?? "未知错误")
        }
        .overlay {
            if viewModel.isLoading {
                LoadingView(progress: viewModel.parseProgress)
            }
        }
    }
}

#Preview {
    MainView()
}
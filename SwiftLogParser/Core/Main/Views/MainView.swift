//
//  MainView.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/5.
//

import SwiftUI

/// 应用主视图 - macOS 风格布局
struct MainView: View {
    @State private var selectedSidebarItem: SidebarItem = .logParser
    @State private var showFileImporter = false
    @State private var showAbout = false
    
    var body: some View {
        NavigationSplitView {
            // 左侧菜单栏
            SidebarView(selectedItem: $selectedSidebarItem)
        } detail: {
            // 右侧内容区域
            ContentAreaView(selectedItem: selectedSidebarItem)
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 1000, minHeight: 700)
        .onReceive(NotificationCenter.default.publisher(
            for: .fileSelected
        )) { _ in
            showFileImporter = true
        }
        .onReceive(NotificationCenter.default.publisher(
            for: .fileSelected
        )) { _ in
            showAbout = true
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            // 处理文件选择逻辑
            NotificationCenter.default.post(
                name: .fileSelected,
                object: result
            )
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
    }
}

/// 左侧菜单栏
struct SidebarView: View {
    @Binding var selectedItem: SidebarItem
    
    var body: some View {
        VStack(spacing: 0) {
            // 菜单栏标题
            headerSection
            
            // 菜单项列表
            menuItemsList
            
            Spacer()
            
            // 底部版本信息
            footerSection
        }
        .frame(width: 240)
        .background(Color(.controlBackgroundColor))
    }
    
    private var headerSection: some View {
        HStack {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.title2)
                .foregroundColor(.white)
            
            Text("菜单栏")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue, Color.blue.opacity(0.8)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private var menuItemsList: some View {
        VStack(spacing: 4) {
            ForEach(SidebarItem.allCases, id: \.self) { item in
                SidebarItemRow(
                    item: item,
                    isSelected: selectedItem == item
                ) {
                    selectedItem = item
                }
            }
        }
        .padding(.top, 8)
    }
    
    private var footerSection: some View {
        VStack(spacing: 4) {
            Text("v1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

/// 菜单项行视图
struct SidebarItemRow: View {
    let item: SidebarItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: item.iconName)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : .primary)
                    .frame(width: 20)
                
                Text(item.title)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                Color.accentColor :
                Color.clear
            )
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 8)
    }
}

/// 右侧内容区域
struct ContentAreaView: View {
    let selectedItem: SidebarItem
    
    var body: some View {
        Group {
            switch selectedItem {
            case .logParser:
                LogParserContentView()
            case .history:
                HistoryView()
            case .settings:
                SettingsContentView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// 菜单项枚举
enum SidebarItem: String, CaseIterable {
    case logParser = "logParser"
    case history = "history"
    case settings = "settings"
    
    var title: String {
        switch self {
        case .logParser:
            return "Log文件解析"
        case .history:
            return "解析历史"
        case .settings:
            return "设置"
        }
    }
    
    var iconName: String {
        switch self {
        case .logParser:
            return "doc.text.magnifyingglass"
        case .history:
            return "clock.arrow.circlepath"
        case .settings:
            return "gearshape"
        }
    }
}

/// 关于页面
struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("日志解析器")
                .font(.title)
                .fontWeight(.bold)
            
            Text("版本 1.0.0")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("用于解析和查看日志文件的 macOS 应用")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("确定") {
                // 关闭关于页面
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(width: 350, height: 300)
    }
}

// MARK: - 扩展通知名称
extension Notification.Name {
    static let fileSelected = Notification.Name("fileSelected")
}

#Preview {
    MainView()
}

//
//  MainView.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/5.
//

import SwiftUI

/// 应用主视图
struct MainView: View {
    var body: some View {
        TabView {
            LogParserView()
                .tabItem {
                    Label("日志解析", systemImage: "doc.text.magnifyingglass")
                }
            
            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gearshape")
                }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

/// 设置页面（占位符）
struct SettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("设置")
                .font(.title)
                .fontWeight(.bold)
            
            Text("设置页面正在开发中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .navigationTitle("设置")
    }
}

#Preview {
    MainView()
}
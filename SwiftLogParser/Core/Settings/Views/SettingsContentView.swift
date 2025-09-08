//
//  SettingsContentView.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/8.
//

import SwiftUI

/// 设置内容视图
struct SettingsContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("设置")
                .font(.title)
                .fontWeight(.bold)
            
            Text("设置功能正在开发中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.controlBackgroundColor))
    }
}

#Preview {
    SettingsContentView()
}
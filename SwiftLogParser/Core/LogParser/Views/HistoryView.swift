//
//  HistoryView.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/8.
//

import SwiftUI

/// 解析历史视图
struct HistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("解析历史")
                .font(.title)
                .fontWeight(.bold)
            
            Text("解析历史功能正在开发中...")
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
    HistoryView()
}
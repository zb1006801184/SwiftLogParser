//
//  ServerLogListItemView.swift
//  SwiftLogParser
//
//  Created by zhubiao07 on 2025/9/17.
//

import SwiftUI

/// 单条日志项视图（仅展示数据，无业务逻辑）
struct ServerLogListItemView: View {
    /// 日志标题
    let title: String
    /// 日志时间字符串
    let time: String
    /// 日志摘要
    let summary: String
    /// 点击回调
    var onTap: (() -> Void)? = nil
    ///是否选中
    var isSelected: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 时间标签
            Text(time)
                .font(.system(size: 12))
                .foregroundColor(.gray)
                .frame(width: 76, alignment: .leading)
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)

            Text(summary)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity,alignment: .leading)
        .padding()
        .contentShape(Rectangle())
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .onTapGesture {
            onTap?()
        }
    }
}

#Preview {
    ServerLogListItemView(
        title: "ERROR /api/logs",
        time: "10:21:33",
        summary: "Null pointer exception at line 42 in Parser.swift",
        onTap: { print("tapped") }
    )
    .frame(maxWidth: .infinity, alignment: .leading)
}

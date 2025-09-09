//
//  LoadingProgressView.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/9.
//

import SwiftUI

/// 日志解析加载进度视图
struct LoadingProgressView: View {
    let progress: Double
    let fileName: String?
    
    var body: some View {
        VStack(spacing: 20) {
            // 动画图标
            Image(systemName: "gearshape.2")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .rotationEffect(.degrees(progress * 360))
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), 
                          value: progress)
            
            VStack(spacing: 12) {
                Text("正在解析日志文件...")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if let fileName = fileName {
                    Text(fileName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            
            VStack(spacing: 8) {
                // 进度条
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle())
                    .frame(width: 300)
                
                // 进度百分比
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // 进度阶段提示
            Text(progressMessage)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.controlBackgroundColor))
    }
    
    /// 根据进度返回相应的提示信息
    private var progressMessage: String {
        switch progress {
        case 0.0..<0.2:
            return "读取文件数据中..."
        case 0.2..<0.8:
            return "解析日志内容中..."
        case 0.8..<1.0:
            return "处理日志数据中..."
        default:
            return "解析完成"
        }
    }
}

#Preview {
    LoadingProgressView(progress: 0.65, fileName: "example.logan")
        .frame(width: 500, height: 400)
}
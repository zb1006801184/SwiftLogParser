//
//  loading_view.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/5.
//

import SwiftUI

struct LoadingView: View {
    let progress: Double
    
    var body: some View {
        ZStack {
            // 半透明背景
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            // 加载内容
            VStack(spacing: 20) {
                // 进度圆环
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(Color.blue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.3), value: progress)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                VStack(spacing: 8) {
                    Text("正在解析日志文件")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(progressDescription)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(30)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .shadow(radius: 10)
        }
    }
    
    private var progressDescription: String {
        switch progress {
        case 0..<0.1:
            return "读取文件数据..."
        case 0.1..<0.7:
            return "解密和解压缩中..."
        case 0.7..<0.9:
            return "解析日志内容..."
        case 0.9..<1.0:
            return "生成输出文件..."
        default:
            return "解析完成"
        }
    }
}

#Preview {
    LoadingView(progress: 0.6)
}
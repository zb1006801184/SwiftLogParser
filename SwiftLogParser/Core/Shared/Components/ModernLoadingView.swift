//
//  ModernLoadingView.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/8.
//

import SwiftUI
import SwiftUIX

/// 现代化加载视图
/// 提供美观的加载动画和进度显示
struct ModernLoadingView: View {
    let progress: Double
    let fileName: String?
    let message: String?
    
    @State private var isAnimating = false
    
    init(progress: Double = 0.0, fileName: String? = nil, message: String? = nil) {
        self.progress = progress
        self.fileName = fileName
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            // 现代化加载动画
            modernLoadingAnimation
            
            // 进度信息
            modernProgressInfo
            
            // 文件名显示
            if let fileName = fileName {
                modernFileNameDisplay(fileName)
            }
            
            // 自定义消息
            if let message = message {
                Text(message)
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DesignSystem.Spacing.lg)
            }
        }
        .padding(DesignSystem.Spacing.xxl)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .fill(DesignSystem.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                        .stroke(DesignSystem.Colors.borderLight, lineWidth: 1)
                )
                .shadow(
                    color: DesignSystem.Colors.shadowMedium,
                    radius: 20,
                    x: 0,
                    y: 10
                )
        )
        .frame(maxWidth: 420)
        .onAppear {
            isAnimating = true
        }
    }
    
    // MARK: - 视图组件
    
    /// 现代化加载动画
    private var modernLoadingAnimation: some View {
        ZStack {
            // 外层旋转圆环
            Circle()
                .stroke(
                    DesignSystem.Colors.primaryLight,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .animation(
                    Animation.linear(duration: 2.0)
                        .repeatForever(autoreverses: false),
                    value: isAnimating
                )
            
            // 中层进度圆环
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    DesignSystem.Colors.primaryGradient,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(-90))
                .animation(DesignSystem.Animation.springSmooth, value: progress)
            
            // 内层脉冲圆环
            Circle()
                .fill(DesignSystem.Colors.primaryLight)
                .frame(width: 50, height: 50)
                .scaleEffect(isAnimating ? 1.2 : 0.8)
                .opacity(isAnimating ? 0.3 : 0.8)
                .animation(
                    Animation.easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true),
                    value: isAnimating
                )
            
            // 中心图标
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.surface)
                    .frame(width: 40, height: 40)
                    .shadow(color: DesignSystem.Colors.shadow, radius: 4, x: 0, y: 2)
                
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(DesignSystem.Colors.primary)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
        }
    }
    
    /// 现代化进度信息
    private var modernProgressInfo: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            // 进度百分比 - 大字体显示
            Text("\(Int(progress * 100))%")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(DesignSystem.Colors.primary)
                .contentTransition(.numericText())
            
            // 状态文本
            Text("正在解析...")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            // 进度条
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: DesignSystem.Colors.primary))
                .frame(width: 200)
                .scaleEffect(y: 2)
        }
    }
    
    /// 现代化文件名显示
    private func modernFileNameDisplay(_ fileName: String) -> some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // 文件图标
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.infoLight)
                    .frame(width: 32, height: 32)
                
                Image(systemName: "doc.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(DesignSystem.Colors.info)
            }
            
            // 文件名
            VStack(alignment: .leading, spacing: 2) {
                Text("正在处理")
                    .font(DesignSystem.Typography.caption)
                    .foregroundColor(DesignSystem.Colors.textTertiary)
                
                Text(fileName)
                    .font(DesignSystem.Typography.subheadline.weight(.medium))
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.surfaceSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .stroke(DesignSystem.Colors.borderLight, lineWidth: 1)
                )
        )
    }
}

/// 简化版加载视图 - 用于小尺寸场景
struct CompactLoadingView: View {
    let message: String
    
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // 现代化小型加载动画
            ZStack {
                Circle()
                    .stroke(DesignSystem.Colors.primaryLight, lineWidth: 2)
                    .frame(width: 20, height: 20)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(DesignSystem.Colors.primary, lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 1.0)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
            }
            
            Text(message)
                .font(DesignSystem.Typography.caption.weight(.medium))
                .foregroundColor(DesignSystem.Colors.textSecondary)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.surfaceSecondary)
        )
        .onAppear {
            isAnimating = true
        }
    }
}

/// 骨架屏加载视图 - 用于列表加载
struct SkeletonLoadingView: View {
    let itemCount: Int
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(0..<itemCount, id: \.self) { _ in
                SkeletonItemView()
            }
        }
    }
}

/// 现代化骨架屏项目视图
struct SkeletonItemView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                // 时间戳骨架
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(DesignSystem.Colors.borderLight)
                    .frame(width: 120, height: 14)
                
                Spacer()
                
                // 标签骨架
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.borderLight)
                    .frame(width: 80, height: 24)
            }
            
            // 内容骨架
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(DesignSystem.Colors.borderLight)
                    .frame(height: 14)
                
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(DesignSystem.Colors.borderLight)
                    .frame(width: 200, height: 14)
                
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                    .fill(DesignSystem.Colors.borderLight)
                    .frame(width: 150, height: 14)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(DesignSystem.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .stroke(DesignSystem.Colors.borderLight, lineWidth: 1)
                )
                .shadow(color: DesignSystem.Colors.shadowSubtle, radius: 4, x: 0, y: 2)
        )
        .opacity(isAnimating ? 0.6 : 1.0)
        .animation(
            Animation.easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true),
            value: isAnimating
        )
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    VStack(spacing: DesignSystem.Spacing.xl) {
        ModernLoadingView(
            progress: 0.6,
            fileName: "example.log",
            message: "正在解析日志文件，请稍候..."
        )
        
        CompactLoadingView(message: "加载中...")
        
        SkeletonLoadingView(itemCount: 3)
    }
    .padding()
    .frame(width: 500)
}

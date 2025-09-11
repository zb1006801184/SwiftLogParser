//
//  ModernSearchBar.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/8.
//

import SwiftUI
import SwiftUIX

/// 现代化搜索栏组件
/// 提供美观的搜索界面，支持实时搜索和清除功能
struct ModernSearchBar: View {
    @Binding var searchText: String
    let placeholder: String
    let onSearch: () -> Void
    let onClear: () -> Void
    
    @State private var isFocused = false
    @State private var isHovered = false
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // 搜索图标 - 现代化设计
            ZStack {
                Circle()
                    .fill(DesignSystem.Colors.primaryLight)
                    .frame(width: 32, height: 32)
                    .scaleEffect(isFocused ? 1.1 : 1.0)
                    .animation(DesignSystem.Animation.springBouncy, value: isFocused)
                
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isFocused ? DesignSystem.Colors.primary : DesignSystem.Colors.textSecondary)
                    .animation(DesignSystem.Animation.quick, value: isFocused)
            }
            
            // 搜索输入框 - 使用SwiftUIX的现代化样式
            TextField(placeholder, text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(DesignSystem.Typography.body)
                .foregroundColor(DesignSystem.Colors.textPrimary)
                .focused($isTextFieldFocused)
                .onSubmit {
                    onSearch()
                }
                .onChange(of: isTextFieldFocused) { _, focused in
                    withAnimation(DesignSystem.Animation.springBouncy) {
                        isFocused = focused
                    }
                }
            
            // 操作按钮组
            HStack(spacing: DesignSystem.Spacing.sm) {
                // 清除按钮 - 现代化设计
                if !searchText.isEmpty {
                    Button(action: {
                        withAnimation(DesignSystem.Animation.springBouncy) {
                            searchText = ""
                            onClear()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(DesignSystem.Colors.errorLight)
                                .frame(width: 28, height: 28)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(DesignSystem.Colors.error)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .transition(.scale.combined(with: .opacity))
                    .help("清除搜索")
                }
                
                // 搜索按钮 - 现代化设计
                Button(action: onSearch) {
                    ZStack {
                        Circle()
                            .fill(DesignSystem.Colors.primaryGradient)
                            .frame(width: 32, height: 32)
                            .shadow(
                                color: DesignSystem.Colors.primary.opacity(0.3),
                                radius: 4,
                                x: 0,
                                y: 2
                            )
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(isHovered ? 1.05 : 1.0)
                .animation(DesignSystem.Animation.springBouncy, value: isHovered)
                .help("执行搜索")
                .onHover { hovering in
                    isHovered = hovering
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                .fill(DesignSystem.Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                        .stroke(borderColor, lineWidth: borderWidth)
                )
                .shadow(
                    color: isFocused ? DesignSystem.Colors.primary.opacity(0.2) : DesignSystem.Colors.shadow,
                    radius: isFocused ? 12 : 8,
                    x: 0,
                    y: isFocused ? 6 : 4
                )
        )
        .scaleEffect(isFocused ? 1.02 : 1.0)
        .animation(DesignSystem.Animation.springBouncy, value: isFocused)
    }
    
    // MARK: - 计算属性
    
    /// 边框颜色
    private var borderColor: Color {
        if isFocused {
            return DesignSystem.Colors.primary
        } else if isHovered {
            return DesignSystem.Colors.borderFocus
        } else {
            return DesignSystem.Colors.border
        }
    }
    
    /// 边框宽度
    private var borderWidth: CGFloat {
        isFocused ? 2 : 1
    }
}

/// 搜索栏扩展 - 支持现代化样式
extension View {
    /// 应用搜索栏现代化样式
    func modernSearchBarStyle() -> some View {
        self
            .background(DesignSystem.Colors.surface)
            .cornerRadius(DesignSystem.CornerRadius.xl)
            .shadow(color: DesignSystem.Colors.shadow, radius: 8, x: 0, y: 4)
    }
}

#Preview {
    VStack(spacing: DesignSystem.Spacing.lg) {
        ModernSearchBar(
            searchText: .constant(""),
            placeholder: "搜索日志内容...",
            onSearch: {},
            onClear: {}
        )
        
        ModernSearchBar(
            searchText: .constant("测试搜索"),
            placeholder: "搜索日志内容...",
            onSearch: {},
            onClear: {}
        )
    }
    .padding()
    .frame(width: 400)
}

//
//  DesignSystem.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/8.
//

import SwiftUI

/// 统一的设计系统 - 提供一致的颜色、字体、间距等设计规范
struct DesignSystem {
    
    // MARK: - 颜色系统
    
    struct Colors {
        // 主色调 - 现代化蓝色系
        static let primary = Color(red: 0.0, green: 0.48, blue: 1.0) // 系统蓝
        static let primaryLight = Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.12)
        static let primaryDark = Color(red: 0.0, green: 0.35, blue: 0.8)
        static let primaryGradient = LinearGradient(
            colors: [primary, primaryDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        // 辅助色 - 现代化灰色系
        static let secondary = Color(red: 0.56, green: 0.56, blue: 0.58)
        static let secondaryLight = Color(red: 0.56, green: 0.56, blue: 0.58).opacity(0.1)
        
        // 功能色 - 现代化配色
        static let success = Color(red: 0.20, green: 0.78, blue: 0.35)
        static let successLight = Color(red: 0.20, green: 0.78, blue: 0.35).opacity(0.12)
        static let warning = Color(red: 1.0, green: 0.58, blue: 0.0)
        static let warningLight = Color(red: 1.0, green: 0.58, blue: 0.0).opacity(0.12)
        static let error = Color(red: 1.0, green: 0.23, blue: 0.19)
        static let errorLight = Color(red: 1.0, green: 0.23, blue: 0.19).opacity(0.12)
        static let info = Color(red: 0.0, green: 0.48, blue: 1.0)
        static let infoLight = Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.12)
        
        // 中性色 - 现代化背景色
        static let background = Color(red: 0.95, green: 0.95, blue: 0.97)
        static let backgroundSecondary = Color(red: 0.98, green: 0.98, blue: 0.99)
        static let surface = Color.white
        static let surfaceElevated = Color.white
        static let surfaceSecondary = Color(red: 0.97, green: 0.97, blue: 0.98)
        
        // 文本色 - 现代化文本配色
        static let textPrimary = Color(red: 0.0, green: 0.0, blue: 0.0)
        static let textSecondary = Color(red: 0.24, green: 0.24, blue: 0.26)
        static let textTertiary = Color(red: 0.56, green: 0.56, blue: 0.58)
        static let textQuaternary = Color(red: 0.70, green: 0.70, blue: 0.72)
        
        // 边框色 - 现代化边框
        static let border = Color(red: 0.78, green: 0.78, blue: 0.80)
        static let borderLight = Color(red: 0.78, green: 0.78, blue: 0.80).opacity(0.5)
        static let borderFocus = primary
        
        // 阴影色 - 现代化阴影
        static let shadow = Color.black.opacity(0.08)
        static let shadowMedium = Color.black.opacity(0.12)
        static let shadowStrong = Color.black.opacity(0.16)
        static let shadowSubtle = Color.black.opacity(0.04)
        
        // 特殊效果色
        static let overlay = Color.black.opacity(0.4)
        static let glass = Color.white.opacity(0.8)
        static let glassDark = Color.black.opacity(0.1)
    }
    
    // MARK: - 间距系统
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - 字体系统
    
    struct Typography {
        // 标题字体
        static let largeTitle = Font.largeTitle.bold()
        static let title = Font.title.bold()
        static let title2 = Font.title2.bold()
        static let title3 = Font.title3.bold()
        
        // 正文字体
        static let headline = Font.headline
        static let subheadline = Font.subheadline
        static let body = Font.body
        static let callout = Font.callout
        static let caption = Font.caption
        static let caption2 = Font.caption2
        
        // 等宽字体（用于代码显示）
        static let code = Font.system(.body, design: .monospaced)
        static let codeSmall = Font.system(.caption, design: .monospaced)
    }
    
    // MARK: - 圆角系统
    
    struct CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let xl: CGFloat = 16
        static let full: CGFloat = 999
    }
    
    // MARK: - 阴影系统
    
    struct Shadow {
        static let small = ShadowStyle(
            color: Colors.shadow,
            radius: 2,
            x: 0,
            y: 1
        )
        
        static let medium = ShadowStyle(
            color: Colors.shadowMedium,
            radius: 4,
            x: 0,
            y: 2
        )
        
        static let large = ShadowStyle(
            color: Colors.shadowStrong,
            radius: 8,
            x: 0,
            y: 4
        )
    }
    
    // MARK: - 动画系统
    
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let springBouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.6)
        static let springSmooth = SwiftUI.Animation.spring(response: 0.6, dampingFraction: 0.8)
        static let easeOut = SwiftUI.Animation.easeOut(duration: 0.3)
        static let easeIn = SwiftUI.Animation.easeIn(duration: 0.3)
    }
    
    // MARK: - 现代化组件样式
    
    struct Components {
        // 卡片样式
        static func cardBackground() -> some View {
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Colors.surface)
                .shadow(color: Colors.shadow, radius: 8, x: 0, y: 4)
        }
        
        // 玻璃效果背景
        static func glassBackground() -> some View {
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .fill(Colors.glass)
                .background(.ultraThinMaterial)
        }
        
        // 现代化按钮背景
        static func primaryButtonBackground() -> some View {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Colors.primaryGradient)
        }
        
        // 输入框样式
        static func inputFieldBackground() -> some View {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Colors.border, lineWidth: 1)
                )
        }
        
        // 聚焦输入框样式
        static func focusedInputFieldBackground() -> some View {
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Colors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: CornerRadius.md)
                        .stroke(Colors.borderFocus, lineWidth: 2)
                )
        }
    }
}

// MARK: - 阴影样式结构体

struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - 视图扩展

extension View {
    /// 应用小阴影
    func shadowSmall() -> some View {
        self.shadow(
            color: DesignSystem.Shadow.small.color,
            radius: DesignSystem.Shadow.small.radius,
            x: DesignSystem.Shadow.small.x,
            y: DesignSystem.Shadow.small.y
        )
    }
    
    /// 应用中阴影
    func shadowMedium() -> some View {
        self.shadow(
            color: DesignSystem.Shadow.medium.color,
            radius: DesignSystem.Shadow.medium.radius,
            x: DesignSystem.Shadow.medium.x,
            y: DesignSystem.Shadow.medium.y
        )
    }
    
    /// 应用大阴影
    func shadowLarge() -> some View {
        self.shadow(
            color: DesignSystem.Shadow.large.color,
            radius: DesignSystem.Shadow.large.radius,
            x: DesignSystem.Shadow.large.x,
            y: DesignSystem.Shadow.large.y
        )
    }
    
    /// 应用标准圆角
    func standardCornerRadius() -> some View {
        self.cornerRadius(DesignSystem.CornerRadius.md)
    }
    
    /// 应用大圆角
    func largeCornerRadius() -> some View {
        self.cornerRadius(DesignSystem.CornerRadius.lg)
    }
    
    /// 应用现代化卡片样式
    func modernCard() -> some View {
        self
            .background(DesignSystem.Components.cardBackground())
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
    }
    
    /// 应用玻璃效果
    func glassEffect() -> some View {
        self
            .background(DesignSystem.Components.glassBackground())
    }
    
    /// 应用现代化输入框样式
    func modernInputField(isFocused: Bool = false) -> some View {
        self
            .background(
                Group {
                    if isFocused {
                        DesignSystem.Components.focusedInputFieldBackground()
                    } else {
                        DesignSystem.Components.inputFieldBackground()
                    }
                }
            )
    }
    
    /// 应用现代化按钮样式
    func modernButton() -> some View {
        self
            .background(DesignSystem.Components.primaryButtonBackground())
            .foregroundColor(.white)
    }
    
    /// 应用悬浮效果
    func floatingEffect() -> some View {
        self
            .shadow(color: DesignSystem.Colors.shadowMedium, radius: 12, x: 0, y: 6)
            .scaleEffect(1.0)
            .animation(DesignSystem.Animation.spring, value: true)
    }
    
    /// 应用现代化分隔线
    func modernDivider() -> some View {
        self
            .frame(height: 1)
            .background(DesignSystem.Colors.borderLight)
    }
}

// MARK: - 按钮样式扩展

extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }
}

extension ButtonStyle where Self == TertiaryButtonStyle {
    static var tertiary: TertiaryButtonStyle { TertiaryButtonStyle() }
}

// MARK: - 主要按钮样式

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.body.weight(.semibold))
            .foregroundColor(.white)
            .frame(minWidth: 120, minHeight: 44)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.primaryGradient)
                    .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
                    .shadow(
                        color: DesignSystem.Colors.primary.opacity(0.3),
                        radius: configuration.isPressed ? 4 : 8,
                        x: 0,
                        y: configuration.isPressed ? 2 : 4
                    )
            )
            .animation(DesignSystem.Animation.springBouncy, value: configuration.isPressed)
    }
}

// MARK: - 次要按钮样式

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.body.weight(.semibold))
            .foregroundColor(DesignSystem.Colors.primary)
            .frame(minWidth: 120, minHeight: 44)
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .stroke(DesignSystem.Colors.primary, lineWidth: 2)
                    )
                    .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
                    .shadow(
                        color: DesignSystem.Colors.shadow,
                        radius: configuration.isPressed ? 2 : 4,
                        x: 0,
                        y: configuration.isPressed ? 1 : 2
                    )
            )
            .animation(DesignSystem.Animation.springBouncy, value: configuration.isPressed)
    }
}

// MARK: - 第三级按钮样式

struct TertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(DesignSystem.Typography.body.weight(.medium))
            .foregroundColor(DesignSystem.Colors.textSecondary)
            .frame(minWidth: 100, minHeight: 40)
            .padding(.horizontal, DesignSystem.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.surfaceSecondary)
                    .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                    .shadow(
                        color: DesignSystem.Colors.shadowSubtle,
                        radius: configuration.isPressed ? 1 : 2,
                        x: 0,
                        y: configuration.isPressed ? 0 : 1
                    )
            )
            .animation(DesignSystem.Animation.springSmooth, value: configuration.isPressed)
    }
}

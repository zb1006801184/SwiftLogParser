//
//  SettingsContentView.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/8.
//

import SwiftUI

/// 设置内容视图
struct SettingsContentView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {
                // 头部标题区域
                headerSection
                
                // 加密密钥配置区域
                encryptionSection
                
                // 底部按钮区域
                bottomButtonsSection
            }
            .padding(DesignSystem.Spacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DesignSystem.Colors.background)
        .alert("提示", isPresented: $viewModel.showAlert) {
            Button("确定") {}
        } message: {
            Text(viewModel.alertMessage)
        }
    }
    
    /// 头部标题区域 - 现代化设计
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // 密钥图标 - 现代化设计
                ZStack {
                    Circle()
                        .fill(DesignSystem.Colors.primaryLight)
                        .frame(width: 56, height: 56)
                        .shadowSmall()
                    
                    Image(systemName: "key.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(DesignSystem.Colors.primary)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("密钥设置")
                        .font(DesignSystem.Typography.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(DesignSystem.Colors.textPrimary)
                    
                    Text("配置Logan日志解析密钥")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundColor(DesignSystem.Colors.textSecondary)
                }
                
                Spacer()
                
                // 使用默认按钮 - 现代化样式
                Button("使用默认") {
                    viewModel.resetToDefault()
                }
                .font(DesignSystem.Typography.callout.weight(.medium))
                .foregroundColor(DesignSystem.Colors.warning)
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .fill(DesignSystem.Colors.warning.opacity(0.1))
                )
            }
        }
    }
    
    /// 加密配置区域 - 现代化设计
    private var encryptionSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // 加密密钥配置标题
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(DesignSystem.Colors.primary)
                    .font(.system(size: 18, weight: .medium))
                
                Text("加密密钥配置")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                
                Spacer()
            }
            
            Divider()
                .background(DesignSystem.Colors.border)
            
            // AES密钥输入
            aesKeyInputSection
            
            // AES向量输入
            aesIvInputSection
            
            // 提示信息
            infoNoticeSection
        }
        .padding(DesignSystem.Spacing.lg)
        .background(DesignSystem.Colors.surfaceElevated)
        .largeCornerRadius()
        .shadowMedium()
    }
    
    
    /// AES密钥输入区域 - 现代化设计
    private var aesKeyInputSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("AES密钥 (Key)")
                .font(DesignSystem.Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            HStack(spacing: DesignSystem.Spacing.md) {
                // 密钥图标
                Image(systemName: "key")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(width: 18)
                
                // 输入框
                TextField("0123456789012345", text: $viewModel.aesKey)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(DesignSystem.Typography.code)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .autocorrectionDisabled()
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 300, height: 32)
                    .onChange(of: viewModel.aesKey) { _, newValue in
                        // 限制输入长度为16位
                        if newValue.count > 16 {
                            viewModel.aesKey = String(newValue.prefix(16))
                        }
                    }
                
                // 清除按钮
                if !viewModel.aesKey.isEmpty {
                    Button(action: viewModel.clearKey) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .font(.system(size: 16))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.surface)
            .standardCornerRadius()
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }
    
    /// AES向量输入区域 - 现代化设计
    private var aesIvInputSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("AES向量 (IV)")
                .font(DesignSystem.Typography.subheadline)
                .fontWeight(.medium)
                .foregroundColor(DesignSystem.Colors.textPrimary)
            
            HStack(spacing: DesignSystem.Spacing.md) {
                // 向量图标
                Image(systemName: "shuffle")
                    .foregroundColor(DesignSystem.Colors.textSecondary)
                    .frame(width: 18)
                
                // 输入框
                TextField("0123456789012345", text: $viewModel.aesIv)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(DesignSystem.Typography.code)
                    .foregroundColor(DesignSystem.Colors.textPrimary)
                    .autocorrectionDisabled()
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 300, height: 32)
                    .onChange(of: viewModel.aesIv) { _, newValue in
                        // 限制输入长度为16位
                        if newValue.count > 16 {
                            viewModel.aesIv = String(newValue.prefix(16))
                        }
                    }
                
                // 清除按钮
                if !viewModel.aesIv.isEmpty {
                    Button(action: viewModel.clearIv) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(DesignSystem.Colors.textSecondary)
                            .font(.system(size: 16))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.surface)
            .standardCornerRadius()
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
        }
    }
    
    /// 信息提示区域 - 现代化设计
    private var infoNoticeSection: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(DesignSystem.Colors.info)
                .font(.system(size: 18, weight: .medium))
            
            Text("密钥和向量都必须是16位字符。如果不设置将使用默认密钥。")
                .font(DesignSystem.Typography.caption)
                .foregroundColor(DesignSystem.Colors.textSecondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Colors.info.opacity(0.08))
        .standardCornerRadius()
    }
    
    /// 底部按钮区域 - 现代化设计
    private var bottomButtonsSection: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Spacer()
            
            // 重置为默认按钮
            Button("重置为默认") {
                viewModel.resetToDefault()
            }
            .buttonStyle(.secondary)
            
            // 保存设置按钮
            Button("保存设置") {
                viewModel.saveSettings()
            }
            .buttonStyle(.primary)
        }
        .padding(.top, DesignSystem.Spacing.sm)
    }
}


#Preview {
    SettingsContentView()
        .frame(width: 800, height: 600)
}

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
            VStack(alignment: .leading, spacing: 20) {
                // 头部标题区域
                headerSection
                
                // 加密密钥配置区域
                encryptionSection
                
                // 底部按钮区域
                bottomButtonsSection
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
        .alert("提示", isPresented: $viewModel.showAlert) {
            Button("确定") {}
        } message: {
            Text(viewModel.alertMessage)
        }
    }
    
    /// 头部标题区域
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 16) {
                // 密钥图标
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: "key.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("密钥设置")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("配置Logan日志解析密钥")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // 使用默认按钮
                Button("使用默认") {
                    viewModel.resetToDefault()
                }
                .font(.callout)
                .foregroundColor(.orange)
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    /// 加密配置区域
    private var encryptionSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 加密密钥配置标题
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
                
                Text("加密密钥配置")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Divider()
            
            // AES密钥输入
            aesKeyInputSection
            
            // AES向量输入
            aesIvInputSection
            
            // 提示信息
            infoNoticeSection
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    /// AES密钥输入区域
    private var aesKeyInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AES密钥 (Key)")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(spacing: 12) {
                // 密钥图标
                Image(systemName: "key")
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                
                // 输入框
                TextField("0123456789012345", text: $viewModel.aesKey)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(.body, design: .monospaced))
                    .autocorrectionDisabled()
                
                // 清除按钮
                if !viewModel.aesKey.isEmpty {
                    Button(action: viewModel.clearKey) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(12)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.separatorColor), lineWidth: 1)
            )
        }
    }
    
    /// AES向量输入区域
    private var aesIvInputSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AES向量 (IV)")
                .font(.subheadline)
                .fontWeight(.medium)
            
            HStack(spacing: 12) {
                // 向量图标
                Image(systemName: "shuffle")
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                
                // 输入框
                TextField("0123456789012345", text: $viewModel.aesIv)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(.body, design: .monospaced))
                    .autocorrectionDisabled()
                
                // 清除按钮
                if !viewModel.aesIv.isEmpty {
                    Button(action: viewModel.clearIv) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(12)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.separatorColor), lineWidth: 1)
            )
        }
    }
    
    /// 信息提示区域
    private var infoNoticeSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle.fill")
                .foregroundColor(.blue)
                .font(.system(size: 16))
            
            Text("密钥和向量都必须是16位字符。如果不设置将使用默认密钥。")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(12)
        .background(Color.blue.opacity(0.08))
        .cornerRadius(8)
    }
    
    /// 底部按钮区域
    private var bottomButtonsSection: some View {
        HStack(spacing: 12) {
            Spacer()
            
            // 重置为默认按钮
            Button("重置为默认") {
                viewModel.resetToDefault()
            }
            .buttonStyle(SecondaryButtonStyle())
            
            // 保存设置按钮
            Button("保存设置") {
                viewModel.saveSettings()
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.top, 8)
    }
}

/// 主要按钮样式
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, weight: .medium))
            .foregroundColor(.white)
            .frame(minWidth: 100, minHeight: 36)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.blue)
                    .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// 次要按钮样式
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.body, weight: .medium))
            .foregroundColor(.blue)
            .frame(minWidth: 100, minHeight: 36)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.blue, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white)
                    )
                    .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            )
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    SettingsContentView()
        .frame(width: 800, height: 600)
}

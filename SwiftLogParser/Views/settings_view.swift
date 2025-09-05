//
//  settings_view.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/5.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settingsService: SettingsService
    @State private var tempSettings: AppSettings
    @State private var validationMessage = ""
    @State private var showValidation = false
    @Environment(\.dismiss) private var dismiss
    
    init(settingsService: SettingsService) {
        self.settingsService = settingsService
        self._tempSettings = State(initialValue: settingsService.settings)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // AES 密钥设置
                GroupBox("AES 解密设置") {
                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("AES 密钥 (16字节)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("输入 AES 密钥", text: $tempSettings.aesKey)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("AES 向量 (16字节)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextField("输入 AES 向量", text: $tempSettings.aesIv)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                        }
                        
                        if tempSettings.isUsingDefaultKeys {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("正在使用默认密钥")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        Button("重置为默认密钥") {
                            tempSettings.resetToDefault()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.vertical, 8)
                }
                
                // 外观设置
                GroupBox("外观设置") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("深色模式", isOn: $tempSettings.isDarkMode)
                    }
                    .padding(.vertical, 8)
                }
                
                // 解析历史
                GroupBox("解析历史") {
                    VStack(alignment: .leading, spacing: 12) {
                        if settingsService.parseHistory.isEmpty {
                            Text("暂无解析历史")
                                .foregroundColor(.secondary)
                                .italic()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 20)
                        } else {
                            ForEach(settingsService.parseHistory.prefix(5)) { history in
                                ParseHistoryRow(history: history)
                                
                                if history.id != settingsService.parseHistory.prefix(5).last?.id {
                                    Divider()
                                }
                            }
                            
                            if settingsService.parseHistory.count > 5 {
                                Text("显示最近 5 条记录，共 \(settingsService.parseHistory.count) 条")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                            }
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            Button("清空历史记录") {
                                settingsService.clearParseHistory()
                            }
                            .foregroundColor(.red)
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                // 操作按钮
                HStack(spacing: 12) {
                    Button("取消") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("保存") {
                        saveSettings()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.top, 20)
            }
            .padding(24)
        }
        .navigationTitle("设置")
        .alert("验证结果", isPresented: $showValidation) {
            Button("确定") { }
        } message: {
            Text(validationMessage)
        }
        .frame(minWidth: 500, minHeight: 600)
    }
    
    private func saveSettings() {
        let validation = tempSettings.validateKeys()
        
        if validation.isValid {
            settingsService.updateSettings(tempSettings)
            validationMessage = "设置已保存"
            showValidation = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                dismiss()
            }
        } else {
            validationMessage = validation.message
            showValidation = true
        }
    }
}

// 解析历史行
struct ParseHistoryRow: View {
    let history: ParseHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(history.fileName)
                    .font(.body)
                    .lineLimit(1)
                
                Spacer()
                
                Text(history.statusDescription)
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(history.statusColor.opacity(0.2))
                    .foregroundColor(history.statusColor)
                    .cornerRadius(4)
            }
            
            HStack {
                Text(history.parseTimeFormatted)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if history.isSuccess {
                    Text("\(history.logCount) 条日志 · \(history.fileSizeFormatted)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let errorMessage = history.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    SettingsView(settingsService: SettingsService())
}

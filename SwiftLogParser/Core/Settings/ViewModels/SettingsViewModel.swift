//
//  SettingsViewModel.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/8.
//

import Foundation
import SwiftUI

/// 设置页面视图模型
class SettingsViewModel: ObservableObject {
    @Published var aesKey: String = ""
    @Published var aesIv: String = ""
    @Published var showAlert: Bool = false
    @Published var alertMessage: String = ""
    
    private let userDefaults = UserDefaults.standard
    private let settingsService: SettingsService
    
    init(settingsService: SettingsService = SettingsServiceImpl()) {
        self.settingsService = settingsService
        loadSettings()
    }
    
    /// 加载保存的设置
    func loadSettings() {
        let savedKey = userDefaults.string(forKey: SettingsKeys.aesKey)
        let savedIv = userDefaults.string(forKey: SettingsKeys.aesIv)
        
        self.aesKey = savedKey ?? LoganConstants.defaultAesKey
        self.aesIv = savedIv ?? LoganConstants.defaultAesIv
    }
    
    /// 保存设置
    func saveSettings() {
        // 验证密钥和向量长度
        guard aesKey.count == 16 else {
            showErrorAlert("AES密钥必须为16位字符")
            return
        }
        
        guard aesIv.count == 16 else {
            showErrorAlert("AES向量必须为16位字符")
            return
        }
        
        // 保存到UserDefaults
        userDefaults.set(aesKey, forKey: SettingsKeys.aesKey)
        userDefaults.set(aesIv, forKey: SettingsKeys.aesIv)
        
        showSuccessAlert("设置已保存")
    }
    
    /// 重置为默认值
    func resetToDefault() {
        aesKey = LoganConstants.defaultAesKey
        aesIv = LoganConstants.defaultAesIv
    }
    
    /// 清除密钥
    func clearKey() {
        aesKey = ""
    }
    
    /// 清除向量
    func clearIv() {
        aesIv = ""
    }
    
    /// 显示错误提示
    private func showErrorAlert(_ message: String) {
        alertMessage = message
        showAlert = true
    }
    
    /// 显示成功提示
    private func showSuccessAlert(_ message: String) {
        alertMessage = message
        showAlert = true
    }
    
    /// 获取当前设置
    func getCurrentSettings() -> LoganSettings {
        return LoganSettings(aesKey: aesKey, aesIv: aesIv)
    }
}
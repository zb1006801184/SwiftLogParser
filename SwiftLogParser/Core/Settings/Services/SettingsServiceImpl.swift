//
//  SettingsServiceImpl.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/5.
//

import Foundation

/// 设置服务实现
class SettingsServiceImpl: SettingsService {
    private let userDefaults = UserDefaults.standard
    private let historyService: HistoryServiceProtocol = HistoryService()
    
    /// 获取 Logan 设置
    func getSettings() -> LoganSettings {
        let savedKey = userDefaults.string(forKey: SettingsKeys.aesKey)
        let savedIv = userDefaults.string(forKey: SettingsKeys.aesIv)
        
        return LoganSettings(
            aesKey: savedKey ?? LoganConstants.defaultAesKey,
            aesIv: savedIv ?? LoganConstants.defaultAesIv
        )
    }
    
    /// 保存 Logan 设置
    func saveSettings(_ settings: LoganSettings) {
        userDefaults.set(settings.aesKey, forKey: SettingsKeys.aesKey)
        userDefaults.set(settings.aesIv, forKey: SettingsKeys.aesIv)
    }
    
    /// 重置为默认设置
    func resetToDefaultSettings() {
        userDefaults.removeObject(forKey: SettingsKeys.aesKey)
        userDefaults.removeObject(forKey: SettingsKeys.aesIv)
    }
    
    /// 添加解析历史
    func addParseHistory(_ history: ParseHistory) {
        // 写入历史记录到持久化
        historyService.addHistory(history)
    }
}

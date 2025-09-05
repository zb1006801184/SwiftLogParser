//
//  SettingsServiceImpl.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/5.
//

import Foundation

/// 设置服务实现
class SettingsServiceImpl: SettingsService {
    /// 获取 Logan 设置
    func getSettings() -> LoganSettings {
        return LoganSettings(
            aesKey: LoganConstants.defaultAesKey,
            aesIv: LoganConstants.defaultAesIv
        )
    }
    
    /// 添加解析历史
    func addParseHistory(_ history: ParseHistory) {
        // TODO: 可以在这里实现持久化存储
        print("解析历史已添加: \(history.fileName)")
    }
}
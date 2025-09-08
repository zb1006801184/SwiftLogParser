//
//  SettingsModel.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/8.
//

import Foundation

/// 应用设置模型
struct AppSettings: Codable {
    var aesKey: String
    var aesIv: String
    
    /// 初始化设置，使用默认值
    init() {
        self.aesKey = LoganConstants.defaultAesKey
        self.aesIv = LoganConstants.defaultAesIv
    }
    
    /// 使用指定值初始化
    init(aesKey: String, aesIv: String) {
        self.aesKey = aesKey
        self.aesIv = aesIv
    }
    
    /// 验证设置是否有效
    var isValid: Bool {
        return aesKey.count == 16 && aesIv.count == 16
    }
    
    /// 转换为LoganSettings
    var toLoganSettings: LoganSettings {
        return LoganSettings(aesKey: aesKey, aesIv: aesIv)
    }
}

/// 设置存储键
enum SettingsKeys {
    static let aesKey = "settings.aes.key"
    static let aesIv = "settings.aes.iv"
}
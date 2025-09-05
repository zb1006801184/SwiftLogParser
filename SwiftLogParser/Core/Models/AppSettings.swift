//
//  app_settings.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/09/05.
//

import Foundation

// MARK: - 应用设置数据模型
struct AppSettings: Codable {
    // MARK: - 属性
    
    /// AES 密钥
    var aesKey: String
    
    /// AES 向量
    var aesIv: String
    
    /// 是否使用深色主题
    var isDarkMode: Bool
    
    // MARK: - 初始化
    
    init(aesKey: String = LoganConstants.defaultAesKey,
         aesIv: String = LoganConstants.defaultAesIv,
         isDarkMode: Bool = true) {
        self.aesKey = aesKey
        self.aesIv = aesIv
        self.isDarkMode = isDarkMode
    }
    
    // MARK: - 默认设置
    
    /// 默认设置实例
    static let `default` = AppSettings()
    
    // MARK: - 计算属性
    
    /// 检查是否使用默认密钥
    var isUsingDefaultKeys: Bool {
        return aesKey == LoganConstants.defaultAesKey && 
               aesIv == LoganConstants.defaultAesIv
    }
    
    // MARK: - 方法
    
    /// 重置为默认设置
    mutating func resetToDefault() {
        aesKey = LoganConstants.defaultAesKey
        aesIv = LoganConstants.defaultAesIv
    }
    
    /// 验证密钥格式
    /// - Returns: 验证结果，包含是否有效和消息
    func validateKeys() -> (isValid: Bool, message: String) {
        // 检查 AES 密钥长度
        if aesKey.count != 16 {
            return (false, "AES 密钥长度必须为 16 字节")
        }
        
        // 检查 AES 向量长度
        if aesIv.count != 16 {
            return (false, "AES 向量长度必须为 16 字节")
        }
        
        // 检查是否包含非 ASCII 字符
        if !aesKey.allSatisfy({ $0.isASCII }) {
            return (false, "AES 密钥只能包含 ASCII 字符")
        }
        
        if !aesIv.allSatisfy({ $0.isASCII }) {
            return (false, "AES 向量只能包含 ASCII 字符")
        }
        
        return (true, "密钥格式正确")
    }
    
    /// 获取密钥的 Data 格式
    /// - Returns: 密钥的 Data 数据
    func getKeyData() -> Data? {
        return aesKey.data(using: .utf8)
    }
    
    /// 获取向量的 Data 格式
    /// - Returns: 向量的 Data 数据
    func getIvData() -> Data? {
        return aesIv.data(using: .utf8)
    }
}

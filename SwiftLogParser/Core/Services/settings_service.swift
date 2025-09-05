//
//  settings_service.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/5.
//

import Foundation
import Combine

class SettingsService: ObservableObject {
    @Published var settings: AppSettings
    @Published var parseHistory: [ParseHistory] = []
    
    private let settingsKey = "app_settings"
    private let historyKey = "parse_history"
    
    init() {
        self.settings = Self.loadSettings()
        self.parseHistory = Self.loadParseHistory()
        Logger.settings.info("设置服务初始化完成")
    }
    
    // 获取当前设置
    func getSettings() -> AppSettings {
        return settings
    }
    
    // 更新设置
    func updateSettings(_ newSettings: AppSettings) {
        self.settings = newSettings
        saveSettings()
        Logger.settings.info("设置已更新")
    }
    
    // 重置为默认设置
    func resetToDefaults() {
        self.settings = AppSettings.default
        saveSettings()
        Logger.settings.info("设置已重置为默认值")
    }
    
    // 添加解析历史
    func addParseHistory(_ history: ParseHistory) {
        parseHistory.insert(history, at: 0)
        
        // 限制历史记录数量（最多保存100条）
        if parseHistory.count > 100 {
            parseHistory = Array(parseHistory.prefix(100))
        }
        
        saveParseHistory()
        Logger.settings.info("添加解析历史记录: \(history.fileName)")
    }
    
    // 清空解析历史
    func clearParseHistory() {
        parseHistory.removeAll()
        saveParseHistory()
        Logger.settings.info("解析历史记录已清空")
    }
    
    // 删除指定历史记录
    func deleteParseHistory(_ history: ParseHistory) {
        if let index = parseHistory.firstIndex(of: history) {
            parseHistory.remove(at: index)
            saveParseHistory()
            Logger.settings.info("删除解析历史记录: \(history.fileName)")
        }
    }
    
    // 保存设置到 UserDefaults
    private func saveSettings() {
        do {
            let data = try JSONEncoder().encode(settings)
            UserDefaults.standard.set(data, forKey: settingsKey)
        } catch {
            Logger.settings.error("保存设置失败: \(error)")
        }
    }
    
    // 从 UserDefaults 加载设置
    private static func loadSettings() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: "app_settings"),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            Logger.settings.info("使用默认设置")
            return AppSettings.default
        }
        
        Logger.settings.info("设置加载完成")
        return settings
    }
    
    // 保存解析历史到 UserDefaults
    private func saveParseHistory() {
        do {
            let data = try JSONEncoder().encode(parseHistory)
            UserDefaults.standard.set(data, forKey: historyKey)
        } catch {
            Logger.settings.error("保存解析历史失败: \(error)")
        }
    }
    
    // 从 UserDefaults 加载解析历史
    private static func loadParseHistory() -> [ParseHistory] {
        guard let data = UserDefaults.standard.data(forKey: "parse_history"),
              let history = try? JSONDecoder().decode([ParseHistory].self, from: data) else {
            Logger.settings.info("解析历史为空")
            return []
        }
        
        Logger.settings.info("解析历史加载完成，共 \(history.count) 条记录")
        return history
    }
}

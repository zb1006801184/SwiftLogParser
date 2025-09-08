//
//  SwiftLogParserApp.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/5.
//

import SwiftUI

@main
struct SwiftLogParserApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            menuCommands
        }
    }
    
    // MARK: - Menu Commands
    private var menuCommands: some Commands {
        Group {
            CommandGroup(after: .newItem) {
                Button("打开日志文件...") {
                    // 触发文件打开操作
                    NotificationCenter.default.post(
                        name: .openLogFile,
                        object: nil
                    )
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Divider()
                
                Button("导出日志...") {
                    // 触发导出操作
                    NotificationCenter.default.post(
                        name: .exportLogs,
                        object: nil
                    )
                }
                .keyboardShortcut("e", modifiers: .command)
            }
            
            CommandGroup(replacing: .help) {
                Button("关于日志解析器") {
                    // 显示关于页面
                    NotificationCenter.default.post(
                        name: .showAbout,
                        object: nil
                    )
                }
            }
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let openLogFile = Notification.Name("openLogFile")
    static let exportLogs = Notification.Name("exportLogs")
    static let showAbout = Notification.Name("showAbout")
}

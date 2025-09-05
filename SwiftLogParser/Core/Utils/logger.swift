//
//  logger.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/5.
//

import Foundation
import os.log

struct Logger {
    private static let subsystem = Bundle.main.bundleIdentifier!
    
    static let ui = os.Logger(subsystem: subsystem, category: "UI")
    static let parser = os.Logger(subsystem: subsystem, category: "Parser")
    static let fileManager = os.Logger(subsystem: subsystem, category: "FileManager")
    static let settings = os.Logger(subsystem: subsystem, category: "Settings")
    
    // 创建默认的 logger
    private static let defaultLogger = os.Logger(subsystem: subsystem, category: "Default")
    
    static func debug(_ message: String, category: os.Logger = defaultLogger) {
        category.debug("\(message)")
    }
    
    static func info(_ message: String, category: os.Logger = defaultLogger) {
        category.info("\(message)")
    }
    
    static func error(_ message: String, category: os.Logger = defaultLogger) {
        category.error("\(message)")
    }
    
    static func fault(_ message: String, category: os.Logger = defaultLogger) {
        category.fault("\(message)")
    }
}

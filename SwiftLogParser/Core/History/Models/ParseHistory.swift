//
//  ParseHistory.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/8.
//

import Foundation

/// 解析历史记录模型
struct ParseHistory: Identifiable, Codable {
    let id: String
    let filePath: String
    let fileName: String
    let parseTime: Date
    let fileSize: Int
    let logCount: Int
    let isSuccess: Bool
    let errorMessage: String?
    let jsonFilePath: String?
    
    init(
        id: String = UUID().uuidString,
        filePath: String,
        fileName: String,
        parseTime: Date = Date(),
        fileSize: Int,
        logCount: Int,
        isSuccess: Bool = true,
        errorMessage: String? = nil,
        jsonFilePath: String? = nil
    ) {
        self.id = id
        self.filePath = filePath
        self.fileName = fileName
        self.parseTime = parseTime
        self.fileSize = fileSize
        self.logCount = logCount
        self.isSuccess = isSuccess
        self.errorMessage = errorMessage
        self.jsonFilePath = jsonFilePath
    }
    
    /// 格式化文件大小
    var formattedFileSize: String {
        return ByteCountFormatter.string(
            fromByteCount: Int64(fileSize),
            countStyle: .file
        )
    }
    
    /// 格式化解析时间
    var formattedParseDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: parseTime)
    }
}
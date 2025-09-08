//
//  FileManagerServiceImpl.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/5.
//

import Foundation

/// 文件管理服务实现
class FileManagerServiceImpl: FileManagerService {
    /// 生成 JSON 文件
    func generateJsonFile(logItems: [LoganLogItem], 
                         originalFileName: String) async throws -> URL {
        // 创建解析结果的数据结构
        let parseResult = [
            "originalFileName": originalFileName,
            "parseTime": Date().iso8601String,
            "logCount": logItems.count,
            "logs": logItems.map { item in
                [
                    "content": item.content,
                    "flag": item.flag,
                    "logTime": item.logTime,
                    "threadName": item.threadName,
                    "threadId": item.threadId,
                    "isMainThread": item.isMainThread
                ]
            }
        ] as [String: Any]
        
        // 转换为 JSON 数据
        let jsonData = try JSONSerialization.data(
            withJSONObject: parseResult,
            options: [.prettyPrinted]
        )
        
        // 生成输出文件名：原始名_时间戳.json，保证唯一且固定 .json 后缀
        let baseName = (originalFileName as NSString).deletingPathExtension
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss_SSS"
        let timestamp = formatter.string(from: Date())
        var outputFileName = "\(baseName)_\(timestamp).json"
        
        // 获取应用沙盒内的文档目录，避免桌面写入权限问题（沙盒始终可写）
        let documentsUrl = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        
        // 若文档目录不存在则尝试创建（通常已存在）
        if !FileManager.default.fileExists(atPath: documentsUrl.path) {
            try FileManager.default.createDirectory(at: documentsUrl, withIntermediateDirectories: true)
        }
        
        var outputUrl = documentsUrl.appendingPathComponent(outputFileName)
        // 若极小概率重名，追加随机后缀
        if FileManager.default.fileExists(atPath: outputUrl.path) {
            outputFileName = "\(baseName)_\(timestamp)_\(UUID().uuidString.prefix(8)).json"
            outputUrl = documentsUrl.appendingPathComponent(outputFileName)
        }
        
        // 写入文件
        try jsonData.write(to: outputUrl)
        
        Logger.info("JSON 文件已生成(应用文档目录): \(outputUrl.path)", 
                   category: Logger.parser)
        return outputUrl
    }
}
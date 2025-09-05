//
//  file_manager_service.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/5.
//

import Foundation
import AppKit

class FileManagerService: ObservableObject {
    private let fileManager = FileManager.default
    
    // 获取桌面路径
    private var desktopURL: URL {
        return fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first!
    }
    
    // 生成 JSON 文件
    func generateJsonFile(logItems: [LoganLogItem], originalFileName: String) async throws {
        let jsonData = try JSONEncoder().encode(logItems)
        
        let fileName = originalFileName.replacingOccurrences(of: ".log", with: "_parsed.json")
        let outputURL = desktopURL.appendingPathComponent(fileName)
        
        try jsonData.write(to: outputURL)
        Logger.info("JSON 文件已生成: \(outputURL.path)", category: Logger.fileManager)
    }
    
    // 导出日志为文本文件
    func exportAsTextFile(logItems: [LoganLogItem], originalFileName: String) async throws {
        var textContent = ""
        
        for item in logItems {
            let timeStr = item.formattedLogTime
            let typeStr = item.logTypeDescription
            let contentStr = item.content ?? ""
            let threadStr = item.threadName ?? "unknown"
            
            textContent += "[\(timeStr)] [\(typeStr)] [\(threadStr)] \(contentStr)\n"
        }
        
        let fileName = originalFileName.replacingOccurrences(of: ".log", with: "_exported.txt")
        let outputURL = desktopURL.appendingPathComponent(fileName)
        
        try textContent.write(to: outputURL, atomically: true, encoding: .utf8)
        Logger.info("文本文件已导出: \(outputURL.path)", category: Logger.fileManager)
    }
    
    // 打开文件选择器
    func selectLogFile() -> URL? {
        let panel = NSOpenPanel()
        panel.title = "选择 Logan 日志文件"
        panel.allowedContentTypes = [.data, .item]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        if panel.runModal() == .OK {
            return panel.url
        }
        
        return nil
    }
    
    // 保存文件对话框
    func saveFile(content: Data, defaultName: String, allowedTypes: [String] = ["json", "txt"]) -> URL? {
        let panel = NSSavePanel()
        panel.title = "保存文件"
        panel.nameFieldStringValue = defaultName
        
        if panel.runModal() == .OK {
            do {
                try content.write(to: panel.url!)
                return panel.url
            } catch {
                Logger.error("保存文件失败: \(error)", category: Logger.fileManager)
            }
        }
        
        return nil
    }
    
    // 检查文件是否存在
    func fileExists(at url: URL) -> Bool {
        return fileManager.fileExists(atPath: url.path)
    }
    
    // 获取文件大小
    func getFileSize(at url: URL) -> Int {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int ?? 0
        } catch {
            Logger.error("获取文件大小失败: \(error)", category: Logger.fileManager)
            return 0
        }
    }
    
    // 在 Finder 中显示文件
    func showInFinder(url: URL) {
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
    }
}

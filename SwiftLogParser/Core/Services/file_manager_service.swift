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
    
    // 获取沙盒可写目录: Application Support/<bundleId>/log
    private var appSupportLogURL: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundleId = Bundle.main.bundleIdentifier ?? "SwiftLogParser"
        let dir = base.appendingPathComponent(bundleId).appendingPathComponent("log")
        // 确保存在
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    // 生成 JSON 文件（优先写入沙盒，可选回退为保存面板）
    func generateJsonFile(logItems: [LoganLogItem], originalFileName: String) async throws {
        let jsonData = try JSONEncoder().encode(logItems)
        let baseName = (originalFileName as NSString).deletingPathExtension
        let fileName = "\(baseName)_parsed.json"
        let outputURL = appSupportLogURL.appendingPathComponent(fileName)
        do {
            try jsonData.write(to: outputURL, options: .atomic)
            Logger.info("JSON 文件已生成: \(outputURL.path)", category: Logger.fileManager)
        } catch {
            Logger.error("写入沙盒失败，尝试保存面板: \(error)", category: Logger.fileManager)
            _ = saveFile(content: jsonData, defaultName: fileName, allowedTypes: ["json"]) // 忽略返回即可
        }
    }
    
    // 导出日志为文本文件（优先写入沙盒）
    func exportAsTextFile(logItems: [LoganLogItem], originalFileName: String) async throws {
        var textContent = ""
        
        for item in logItems {
            let timeStr = item.formattedLogTime
            let typeStr = item.logTypeDescription
            let contentStr = item.content ?? ""
            let threadStr = item.threadName ?? "unknown"
            
            textContent += "[\(timeStr)] [\(typeStr)] [\(threadStr)] \(contentStr)\n"
        }
        
        let baseName = (originalFileName as NSString).deletingPathExtension
        let fileName = "\(baseName)_exported.txt"
        let outputURL = appSupportLogURL.appendingPathComponent(fileName)
        do {
            try textContent.write(to: outputURL, atomically: true, encoding: .utf8)
            Logger.info("文本文件已导出: \(outputURL.path)", category: Logger.fileManager)
        } catch {
            Logger.error("写入沙盒失败，尝试保存面板: \(error)", category: Logger.fileManager)
            _ = saveFile(content: textContent.data(using: .utf8)!, defaultName: fileName, allowedTypes: ["txt"]) 
        }
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
        panel.allowedFileTypes = allowedTypes
        
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

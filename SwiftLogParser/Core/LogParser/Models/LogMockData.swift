//  LogMockData.swift
//  SwiftLogParser
//  Created by zhubiao on 2025/9/9.

import Foundation

struct LogMockData {
    static let mockLogItems: [LoganLogItem] = [
        // 性能指标日志
        LoganLogItem(
            content: "App performance metrics: FPS=60.0, Memory usage=245MB, CPU usage=12%",
            flag: "1",
            logTime: "2025-09-09 10:30:15.123",
            threadName: "main",
            threadId: "1",
            isMainThread: "1"
        ),
        LoganLogItem(
            content: "Memory allocation performance: Allocated 50MB for image cache",
            flag: "1",
            logTime: "2025-09-09 10:30:16.456",
            threadName: "background",
            threadId: "2",
            isMainThread: "0"
        ),
        // 错误日志
        LoganLogItem(
            content: "Network request failed with error: Connection timeout",
            flag: "2",
            logTime: "2025-09-09 10:30:17.789",
            threadName: "network",
            threadId: "3",
            isMainThread: "0"
        ),
        LoganLogItem(
            content: "Database ERROR: Failed to insert record into user_table",
            flag: "2",
            logTime: "2025-09-09 10:30:18.012",
            threadName: "database",
            threadId: "4",
            isMainThread: "0"
        ),
        LoganLogItem(
            content: "Critical error occurred in payment processing module",
            flag: "2",
            logTime: "2025-09-09 10:30:19.345",
            threadName: "payment",
            threadId: "5",
            isMainThread: "0"
        ),
        // 警告日志
        LoganLogItem(
            content: "Warning: Low memory condition detected, clearing cache",
            flag: "3",
            logTime: "2025-09-09 10:30:20.678",
            threadName: "main",
            threadId: "1",
            isMainThread: "1"
        ),
        LoganLogItem(
            content: "WARN: API response time exceeds threshold (5.2s > 3.0s)",
            flag: "3",
            logTime: "2025-09-09 10:30:21.901",
            threadName: "api",
            threadId: "6",
            isMainThread: "0"
        ),
        LoganLogItem(
            content: "Warning: Deprecated method called in legacy module",
            flag: "3",
            logTime: "2025-09-09 10:30:22.234",
            threadName: "legacy",
            threadId: "7",
            isMainThread: "0"
        ),
        // 信息日志
        LoganLogItem(
            content: "User login successful: user_id=12345, session_id=abc123",
            flag: "4",
            logTime: "2025-09-09 10:30:23.567",
            threadName: "auth",
            threadId: "8",
            isMainThread: "0"
        ),
        LoganLogItem(
            content: "Info: Application started successfully in 2.3 seconds",
            flag: "4",
            logTime: "2025-09-09 10:30:24.890",
            threadName: "main",
            threadId: "1",
            isMainThread: "1"
        ),
        LoganLogItem(
            content: "INFO: Cache updated with 150 new entries",
            flag: "4",
            logTime: "2025-09-09 10:30:25.123",
            threadName: "cache",
            threadId: "9",
            isMainThread: "0"
        ),
        LoganLogItem(
            content: "User preferences loaded successfully from cloud storage",
            flag: "4",
            logTime: "2025-09-09 10:30:26.456",
            threadName: "sync",
            threadId: "10",
            isMainThread: "0"
        ),
        // 通用日志
        LoganLogItem(
            content: "Application lifecycle event: didEnterBackground",
            flag: "0",
            logTime: "2025-09-09 10:30:27.789",
            threadName: "main",
            threadId: "1",
            isMainThread: "1"
        ),
        LoganLogItem(
            content: "Configuration loaded: debug_mode=false, analytics_enabled=true",
            flag: "0",
            logTime: "2025-09-09 10:30:28.012",
            threadName: "config",
            threadId: "11",
            isMainThread: "0"
        ),
        LoganLogItem(
            content: "Background task completed: data_sync_task finished in 1.5s",
            flag: "0",
            logTime: "2025-09-09 10:30:29.345",
            threadName: "background",
            threadId: "2",
            isMainThread: "0"
        )
    ]
}

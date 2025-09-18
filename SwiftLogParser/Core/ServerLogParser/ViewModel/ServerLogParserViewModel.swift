//
//  S.swift
//  SwiftLogParser
//
//  Created by zhubiao07 on 2025/9/17.
//

import Combine
import Foundation

class ServerLogParserViewModel: ObservableObject {

    // 开始时间
    @Published var startTime: Date = Date()

    // 结束时间
    @Published var endTime: Date = Date()

    // 选中的 item index
    @Published var selectedIndex: Int?

    /// 时间选择
    /// 根据 index 设置开始或结束时间
    /// - Parameters:
    ///   - index: 0 表示开始时间，1 表示结束时间
    func datePicker(index: Int) {
        switch index {
        case 0: break

        case 1: break

        default:
            break
        }
    }

    // 搜索关键字
    func search() {

    }
    
    // 点击 item
    func selectItem(at index: Int) {
        selectedIndex = index
    }

    /// 格式化日期为 yyyy-MM-dd 字符串
    func formatDateToYearMonthDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

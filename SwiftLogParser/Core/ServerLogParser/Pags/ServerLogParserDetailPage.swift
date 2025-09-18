//
//  ServerLogParserDetailPage.swift
//  SwiftLogParser
//
//  Created by zhubiao07 on 2025/9/17.
//

import SwiftUI

struct ServerLogParserDetailPage: View {
    var logContent: String = "暂无选中的日志"
    
    var body: some View {
        Text("\(logContent)")
    }
}

#Preview {
    ServerLogParserDetailPage()
}

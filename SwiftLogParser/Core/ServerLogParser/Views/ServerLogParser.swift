//
//  ServerLogParser.swift
//  SwiftLogParser
//
//  Created by zhubiao07 on 2025/9/17.
//

import SwiftUI

struct ServerLogParser: View {

    @StateObject var viewModel: ServerLogParserViewModel =
        ServerLogParserViewModel()

    var body: some View {
        VStack {
            _buildTopBar()
            Spacer()
            HStack {
                Spacer()
                Button(
                    action: {
                        // 示例按钮，可扩展其他功能
                    }
                ) {
                    Text("add")
                        .font(.title2)
                        .padding()
                }
            }
        }
        
    }

    //顶部筛选、搜索栏
    private func _buildTopBar() -> some View {
        HStack () {
            // 开始时间筛选按钮
            _buildTimeFilterButton(
                time: viewModel.formatDateToYearMonthDay(viewModel.startTime),
                action: {
                }
            )
            Text("~")
            // 结束时间筛选按钮
            _buildTimeFilterButton(
                time: viewModel.formatDateToYearMonthDay(viewModel.endTime),
                action: {
                }
            )
            //3. 搜素框
            Spacer()
            //4. 搜索确认按钮
        }.frame(
            height: 40
        )
        .background(Color.white)
    }

    // 时间筛选按钮构建
    private func _buildTimeFilterButton(time: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(time )
                    .font(.callout)
                    .foregroundColor(.gray)
            }
            .padding(8)
        }
    }

}

#Preview {
    ServerLogParser()
}

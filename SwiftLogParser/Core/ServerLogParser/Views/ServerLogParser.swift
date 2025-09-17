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
            //顶部筛选、搜索栏
            _buildTopBar()
            Spacer()
            Text(viewModel.formatDateToYearMonthDay(viewModel.startTime))
            Text(viewModel.formatDateToYearMonthDay(viewModel.endTime))
            Spacer()
        }

    }

    //顶部筛选、搜索栏
    private func _buildTopBar() -> some View {
        HStack () {
            // 开始时间筛选按钮
            _buildTimeFilterButton(
              
                binding: $viewModel.startTime,
                action: {}
            )
            Text("~")
            // 结束时间筛选按钮
            _buildTimeFilterButton(
                binding: $viewModel.endTime,
                action: {}
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
    private func _buildTimeFilterButton(
        binding: Binding<Date>,
        action: @escaping () -> Void
    ) -> some View {
      return  DatePicker(
            "",
            selection: binding,
            displayedComponents: .date
        )
        .labelsHidden()
    }

}

#Preview {
    ServerLogParser()
}

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
        HStack {
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
            _buildSearchField()
            //4. 搜索确认按钮
            _buildSearchButton()
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
        return DatePicker(
            "",
            selection: binding,
            displayedComponents: .date
        )
        .labelsHidden()
    }

    //搜索框构建
    private func _buildSearchField() -> some View {
        TextField("搜索日志内容", text: .constant(""))
            .textFieldStyle(RoundedBorderTextFieldStyle())
            // 占满可用宽度的正确写法
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    //搜索确认按钮
    private func _buildSearchButton() -> some View {
        Button(
            action: {
                viewModel.search()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .frame(width: 16, height: 16)

                    Text("搜索")
                }
                .foregroundColor(.white)
            }
            .padding(4)
            .background(Color.blue)
            .cornerRadius(6)
            .buttonStyle(.plain)
    }

}

#Preview {
    ServerLogParser()
}

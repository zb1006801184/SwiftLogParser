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
            //日志列表
            _buildLogList()
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
    
    //日志列表（改为 List）
    private func _buildLogList() -> some View {
       List {
            // 示例数据：后续替换为 viewModel 的真实数据源
            ForEach(0..<20000, id: \.self) { idx in
                ServerLogListItemView(
                    title: "日志 #\(idx)",
                    time: "09:3\(idx % 10)",
                    summary: "这里是日志的简要内容，展示两行以内……"
                )
//                .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
    }

}

#Preview {
    ServerLogParser()
}

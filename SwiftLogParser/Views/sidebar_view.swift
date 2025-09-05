//
//  sidebar_view.swift
//  SwiftLogParser
//
//  Created by zhubiao on 2025/9/5.
//

import SwiftUI

struct SidebarView: View {
    @ObservedObject var viewModel: MainViewModel
    @Binding var showSettings: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // 文件信息区域
            FileInfoSection(viewModel: viewModel)
            
            Divider()
            
            // 搜索和筛选区域
            SearchFilterSection(viewModel: viewModel)
            
            Divider()
            
            // 统计信息区域
            StatisticsSection(viewModel: viewModel)
            
            Spacer()
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// 文件信息区域
struct FileInfoSection: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("文件信息")
                .font(.headline)
                .foregroundColor(.primary)
            
            if !viewModel.currentFileName.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.blue)
                        Text(viewModel.currentFileName)
                            .font(.caption)
                            .lineLimit(2)
                    }
                    
                    Text("共 \(viewModel.logItems.count) 条日志")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color(NSColor.tertiarySystemFill))
                .cornerRadius(6)
            } else {
                Text("未选择文件")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// 搜索和筛选区域
struct SearchFilterSection: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("搜索与筛选")
                .font(.headline)
                .foregroundColor(.primary)
            
            // 搜索框
            VStack(alignment: .leading, spacing: 4) {
                Text("搜索关键词")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("输入关键词...", text: $viewModel.searchText)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
            // 日志类型筛选
            VStack(alignment: .leading, spacing: 4) {
                Text("日志类型")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Picker("日志类型", selection: $viewModel.selectedLogType) {
                    Text("全部日志").tag("全部日志")
                    ForEach(["2", "3", "4", "5", "6", "7", "8"], id: \.self) { type in
                        HStack {
                            Circle()
                                .fill(logTypeColors[type] ?? .gray)
                                .frame(width: 8, height: 8)
                            Text(logTypeMapping[type] ?? "未知")
                        }
                        .tag(type)
                    }
                }
                .pickerStyle(.menu)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// 统计信息区域
struct StatisticsSection: View {
    @ObservedObject var viewModel: MainViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("统计信息")
                .font(.headline)
                .foregroundColor(.primary)
            
            let stats = viewModel.logStatistics
            
            VStack(spacing: 8) {
                StatItem(
                    icon: "doc.text",
                    title: "总日志数",
                    value: "\(stats.total)",
                    color: .blue
                )
                
                StatItem(
                    icon: "line.3.horizontal.decrease.circle",
                    title: "筛选结果",
                    value: "\(stats.filtered)",
                    color: .green
                )
            }
            
            if !stats.types.isEmpty {
                Text("类型分布")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 4) {
                    ForEach(Array(stats.types.sorted(by: { $0.value > $1.value })), id: \.key) { type, count in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(logTypeColors.first(where: { logTypeMapping[$0.key] == type })?.value ?? .gray)
                                .frame(width: 6, height: 6)
                            
                            Text(type)
                                .font(.caption2)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text("\(count)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// 统计项组件
struct StatItem: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.callout)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color(NSColor.tertiarySystemFill))
        .cornerRadius(6)
    }
}

#Preview {
    SidebarView(
        viewModel: MainViewModel(),
        showSettings: .constant(false)
    )
    .frame(width: 300, height: 600)
}
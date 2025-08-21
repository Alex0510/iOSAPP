//
//  VersionHistoryView.swift
//  版本历史查看界面
//  展示App Store应用的历史版本信息

import SwiftUI
import Combine

/// 版本历史视图
struct VersionHistoryView: View {
    let appId: String
    let appName: String
    
    @StateObject private var versionService = VersionQueryService.shared
    @State private var versions: [VersionQueryService.VersionInfo] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedEndpoint: VersionQueryService.APIEndpoint = .timbrd
    @State private var searchText = ""
    
    var filteredVersions: [VersionQueryService.VersionInfo] {
        if searchText.isEmpty {
            return versions
        } else {
            return versions.filter { version in
                version.version.localizedCaseInsensitiveContains(searchText) ||
                (version.releaseNotes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏和API选择器
                headerSection
                
                // 版本列表
                if isLoading {
                    loadingView
                } else if let errorMessage = errorMessage {
                    errorView(errorMessage)
                } else if filteredVersions.isEmpty {
                    emptyView
                } else {
                    versionList
                }
            }
            .navigationTitle("\(appName) 版本历史")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    refreshButton
                }
            }
        }
        .onAppear {
            loadVersions()
        }
    }
    
    // MARK: - 视图组件
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("搜索版本或更新说明", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("清除") {
                        searchText = ""
                    }
                    .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // API端点选择器
            Picker("数据源", selection: $selectedEndpoint) {
                Text("Timbrd (最快)").tag(VersionQueryService.APIEndpoint.timbrd)
                Text("Bilin (完善)").tag(VersionQueryService.APIEndpoint.bilin)
                Text("Agzy (官方)").tag(VersionQueryService.APIEndpoint.agzy)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            .onChange(of: selectedEndpoint) { _ in
                loadVersions()
            }
        }
        .padding(.vertical)
        .background(Color(.systemGroupedBackground))
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("正在查询版本信息...")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("查询失败")
                .font(.headline)
            
            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("重试") {
                loadVersions()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("未找到版本信息")
                .font(.headline)
            
            Text("请尝试切换数据源或检查App ID是否正确")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var versionList: some View {
        List(filteredVersions) { version in
            VersionRowView(version: version, appId: appId)
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
        .listStyle(PlainListStyle())
        .refreshable {
            await refreshVersions()
        }
    }
    
    private var refreshButton: some View {
        Button(action: loadVersions) {
            Image(systemName: "arrow.clockwise")
        }
        .disabled(isLoading)
    }
    
    // MARK: - 方法
    
    private func loadVersions() {
        isLoading = true
        errorMessage = nil
        
        versionService.queryVersions(for: appId, preferredEndpoint: selectedEndpoint) { result in
            DispatchQueue.main.async {
                self.isLoading = false
                
                if result.success {
                    self.versions = result.versions.sorted { version1, version2 in
                        // 按版本号降序排列（最新版本在前）
                        version1.version.compare(version2.version, options: .numeric) == .orderedDescending
                    }
                    self.errorMessage = nil
                } else {
                    self.errorMessage = result.error?.localizedDescription ?? "未知错误"
                    self.versions = []
                }
            }
        }
    }
    
    private func refreshVersions() async {
        await withCheckedContinuation { continuation in
            loadVersions()
            // 简单的延迟来等待加载完成
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
    }
}

/// 版本行视图
struct VersionRowView: View {
    let version: VersionQueryService.VersionInfo
    let appId: String
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 版本号和发布日期
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("版本 \(version.version)")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let releaseDate = version.releaseDate {
                        Text(formatDate(releaseDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let fileSize = version.fileSize {
                        Text(formatFileSize(fileSize))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // 展开的详细信息
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    if let bundleId = version.bundleId {
                        HStack {
                            Text("Bundle ID:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(bundleId)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    if let releaseNotes = version.releaseNotes, !releaseNotes.isEmpty {
                        Text("更新说明:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(releaseNotes)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .padding(.leading, 8)
                    }
                    
                    // 操作按钮
                    HStack(spacing: 12) {
                        Button("下载此版本") {
                            downloadVersion()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        
                        Button("复制版本号") {
                            copyVersionNumber()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.top, 4)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 4)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - 辅助方法
    
    private func formatDate(_ dateString: String) -> String {
        // 尝试解析不同格式的日期
        let formatters = [
            "yyyy-MM-dd",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd HH:mm:ss"
        ]
        
        for format in formatters {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            if let date = formatter.date(from: dateString) {
                let displayFormatter = DateFormatter()
                displayFormatter.dateStyle = .medium
                displayFormatter.locale = Locale(identifier: "zh_CN")
                return displayFormatter.string(from: date)
            }
        }
        
        return dateString
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func downloadVersion() {
        // TODO: 集成下载功能
        // 这里应该调用Downloads.shared.add()方法添加下载任务
        print("下载版本 \(version.version) for App ID: \(appId)")
    }
    
    private func copyVersionNumber() {
        UIPasteboard.general.string = version.version
        // TODO: 显示复制成功的提示
    }
}

// MARK: - 预览

struct VersionHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        VersionHistoryView(appId: "123456789", appName: "示例应用")
    }
}
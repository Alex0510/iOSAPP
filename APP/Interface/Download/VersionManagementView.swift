//
//  VersionManagementView.swift
//  of pxx917144686
//
//  版本管理界面
//  展示APP的历史版本信息和查询功能
//

import SwiftUI
import Combine

/// 版本信息结构
struct VersionInfo: Identifiable {
    let id = UUID()
    let version: String
    let versionId: String
    let source: String
}

/// 版本查询结果
struct VersionQueryResult {
    let appName: String
    let appId: String
    let currentVersion: String?
    let currentVersionId: String?
    let historyVersions: [VersionInfo]
    let queryTime: Date
    let sources: [String]
}

/// 版本管理主视图
struct VersionManagementView: View {
    @State private var appStoreURL = ""
    @State private var showingURLInput = false
    @State private var selectedVersion: VersionInfo?
    @State private var showingVersionDetail = false
    @State private var isLoading = false
    @State private var queryResult: VersionQueryResult?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            content
                .navigationTitle("版本管理")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            showingURLInput = true
                        } label: {
                            Image(systemName: "magnifyingglass")
                        }
                    }
                }
        }
        .sheet(isPresented: $showingURLInput) {
            URLInputView(appStoreURL: $appStoreURL) { url in
                queryVersions(from: url)
            }
        }
        .sheet(isPresented: $showingVersionDetail) {
            if let version = selectedVersion {
                VersionDetailView(version: version)
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        if isLoading {
            loadingView
        } else if let result = queryResult {
            resultView(result: result)
        } else if let error = errorMessage {
            errorView(error: error)
        } else {
            emptyStateView
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("正在查询版本信息...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "app.badge")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("版本查询")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("输入App Store链接查询应用的历史版本信息")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("开始查询") {
                showingURLInput = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("查询失败")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("重试") {
                showingURLInput = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func resultView(result: VersionQueryResult) -> some View {
        List {
            // 应用信息部分
            Section {
                AppInfoCard(result: result)
            }
            
            // 当前版本部分
            if let currentVersion = result.currentVersion,
               let currentVersionId = result.currentVersionId {
                Section("当前版本") {
                    CurrentVersionRow(version: currentVersion, versionId: currentVersionId)
                }
            }
            
            // 历史版本部分
            if !result.historyVersions.isEmpty {
                Section("历史版本 (\(result.historyVersions.count))") {
                    ForEach(result.historyVersions) { version in
                        VersionRow(version: version) {
                            selectedVersion = version
                            showingVersionDetail = true
                        }
                    }
                }
            }
            
            // 数据源信息
            Section("数据源") {
                ForEach(result.sources, id: \.self) { source in
                    HStack {
                        Image(systemName: sourceIcon(for: source))
                            .foregroundColor(sourceColor(for: source))
                        Text(sourceName(for: source))
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .refreshable {
            if let result = queryResult {
                queryVersions(appId: result.appId, appName: result.appName)
            }
        }
    }
    
    private func queryVersions(from url: String) {
        isLoading = true
        errorMessage = nil
        
        // 模拟查询过程
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // 这里应该调用实际的版本查询服务
            // 现在使用模拟数据
            let mockResult = VersionQueryResult(
                appName: "示例应用",
                appId: "123456789",
                currentVersion: "1.2.3",
                currentVersionId: "987654321",
                historyVersions: [
                    VersionInfo(version: "1.2.2", versionId: "987654320", source: "i4cn"),
                    VersionInfo(version: "1.2.1", versionId: "987654319", source: "bilin"),
                    VersionInfo(version: "1.2.0", versionId: "987654318", source: "timbrd")
                ],
                queryTime: Date(),
                sources: ["i4cn", "bilin", "timbrd"]
            )
            
            queryResult = mockResult
            isLoading = false
        }
    }
    
    private func queryVersions(appId: String, appName: String) {
        queryVersions(from: "")
    }
    
    // MARK: - Helper Methods
    
    private func sourceIcon(for source: String) -> String {
        switch source {
        case "i4cn": return "globe.asia.australia"
        case "bilin": return "globe.europe.africa"
        case "timbrd": return "globe.americas"
        default: return "globe"
        }
    }
    
    private func sourceColor(for source: String) -> Color {
        switch source {
        case "i4cn": return .blue
        case "bilin": return .green
        case "timbrd": return .orange
        default: return .gray
        }
    }
    
    private func sourceName(for source: String) -> String {
        switch source {
        case "i4cn": return "I4CN"
        case "bilin": return "Bilin"
        case "timbrd": return "Timbrd"
        default: return source.capitalized
        }
    }
}

/// 应用信息卡片
struct AppInfoCard: View {
    let result: VersionQueryResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.appName)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("App ID: \(result.appId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(result.historyVersions.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("历史版本")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Label("查询时间", systemImage: "clock")
                Spacer()
                Text(result.queryTime.formatted(date: .abbreviated, time: .shortened))
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

/// 当前版本行
struct CurrentVersionRow: View {
    let version: String
    let versionId: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(version)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Version ID: \(versionId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Label("当前", systemImage: "star.fill")
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

/// 版本行
struct VersionRow: View {
    let version: VersionInfo
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(version.version)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("Version ID: \(version.versionId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Label(sourceName(for: version.source), systemImage: sourceIcon(for: version.source))
                        .font(.caption)
                        .foregroundColor(sourceColor(for: version.source))
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
    
    private func sourceIcon(for source: String) -> String {
        switch source {
        case "i4cn": return "globe.asia.australia"
        case "bilin": return "globe.europe.africa"
        case "timbrd": return "globe.americas"
        default: return "globe"
        }
    }
    
    private func sourceColor(for source: String) -> Color {
        switch source {
        case "i4cn": return .blue
        case "bilin": return .green
        case "timbrd": return .orange
        default: return .gray
        }
    }
    
    private func sourceName(for source: String) -> String {
        switch source {
        case "i4cn": return "I4CN"
        case "bilin": return "Bilin"
        case "timbrd": return "Timbrd"
        default: return source.capitalized
        }
    }
}

/// URL输入视图
struct URLInputView: View {
    @Binding var appStoreURL: String
    let onSubmit: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var inputText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("App Store链接")
                        .font(.headline)
                    
                    TextField("https://apps.apple.com/app/...", text: $inputText)
                        .textFieldStyle(.roundedBorder)
                        .disableAutocorrection(true)
                    
                    Text("请输入完整的App Store应用链接")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button("开始查询") {
                    appStoreURL = inputText
                    onSubmit(inputText)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(inputText.isEmpty)
                
                Spacer()
            }
            .padding()
            .navigationTitle("查询版本")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            inputText = appStoreURL
        }
    }
}

/// 版本详情视图
struct VersionDetailView: View {
    let version: VersionInfo
    @Environment(\.dismiss) private var dismiss
    @State private var showingDownloadOptions = false
    
    var body: some View {
        NavigationView {
            List {
                Section("版本信息") {
                    DetailRow(title: "版本号", value: version.version)
                    DetailRow(title: "版本ID", value: version.versionId)
                    DetailRow(title: "数据源", value: sourceName(for: version.source))
                }
                
                Section("操作") {
                    Button {
                        copyToClipboard(version.versionId)
                    } label: {
                        Label("复制版本ID", systemImage: "doc.on.doc")
                    }
                    
                    Button {
                        showingDownloadOptions = true
                    } label: {
                        Label("下载此版本", systemImage: "arrow.down.circle")
                    }
                }
            }
            .navigationTitle("版本详情")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
        .confirmationDialog("下载版本 \(version.version)", isPresented: $showingDownloadOptions) {
            Button("添加到下载队列") {
                addToDownloadQueue()
            }
            Button("立即下载") {
                startImmediateDownload()
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("选择下载方式")
        }
    }
    
    private func sourceName(for source: String) -> String {
        switch source {
        case "i4cn": return "I4CN"
        case "bilin": return "Bilin"
        case "timbrd": return "Timbrd"
        default: return source.capitalized
        }
    }
    
    private func copyToClipboard(_ text: String) {
        // 在macOS上使用NSPasteboard
        #if os(macOS)
        NSPasteboard.general.setString(text, forType: .string)
        #else
        // 在iOS上使用UIPasteboard
        UIPasteboard.general.string = text
        #endif
    }
    
    private func addToDownloadQueue() {
        // 实现添加到下载队列的逻辑
        // 这里需要与现有的下载系统集成
    }
    
    private func startImmediateDownload() {
        // 实现立即下载的逻辑
        // 这里需要与现有的下载系统集成
    }
}

/// 详情行
struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    VersionManagementView()
}
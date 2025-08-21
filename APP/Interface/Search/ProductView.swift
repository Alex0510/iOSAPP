//
//  ProductView.swift
//  Created by pxx917144686 on 2025/08/19.
//

import ApplePackage
import Kingfisher
import SwiftUI

// 搜索视图，显示APP的详细信息
struct ProductView: View {
    // 要显示的APP归档信息
    let archive: iTunesResponse.iTunesArchive
    // 地区代码
    let region: String
    // 账户状态管理对象
    @StateObject var vm = AppStore.this
    // 下载管理器
    @StateObject var dvm = Downloads.shared
    // 版本查询服务
    private let versionService = VersionQueryService.shared
    // @StateObject var versionService = VersionQueryService.shared
    // 版本管理相关状态
    @State private var showingVersionSelector = false
    @State private var versions: [VersionModels.AppVersion] = []
    @State private var loadingVersions = false
    @State private var versionError: String?
    // 移除本地缓存，使用VersionQueryService的内置缓存[:]
    
    // MARK: - Version Manager (Merged from VersionManager.swift)
    private func fetchVersions(for request: VersionModels.VersionFetchRequest, account: AppStore.Account) async throws -> VersionModels.VersionFetchResponse {
        // 使用VersionQueryService查询版本信息
        return try await withCheckedThrowingContinuation { continuation in
            versionService.queryVersions(appId: request.appId) { result in
                // 检查查询是否成功
                guard result.success else {
                    let errorMessage = result.error ?? "版本查询失败"
                    let error = NSError(domain: "VersionQuery", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    continuation.resume(throwing: error)
                    return
                }
                
                // 转换结果格式
                let versions = result.versions.map { versionInfo in
                    VersionModels.AppVersion(
                        id: versionInfo.id,
                        appId: request.appId,
                        versionString: versionInfo.version,
                        buildNumber: nil,
                        releaseDate: nil,
                        fileSize: versionInfo.fileSize,
                        isLatest: false,
                        releaseNotes: versionInfo.releaseNotes,
                        minimumOSVersion: nil
                    )
                }
                
                let response = VersionModels.VersionFetchResponse(
                    appId: request.appId,
                    versions: versions,
                    fromCache: false
                )
                
                continuation.resume(returning: response)
            }
        }
    }

    // 初始化方法
    init(archive: iTunesResponse.iTunesArchive, region: String) {
        self.archive = archive
        self.region = region
    }

    // 符合地区条件的账户列表
    var eligibleAccounts: [AppStore.Account] {
        vm.accounts.filter { $0.countryCode == region }
    }

    // 根据选中的ID获取账户对象
    var account: AppStore.Account? {
        vm.accounts.first { $0.id == selection }
    }

    // 选中的账户ID
    @State var selection: AppStore.Account.ID = .init()
    // 是否正在获取下载URL
    @State var obtainDownloadURL = false
    // 提示信息
    @State var hint: String = ""
    // 许可证提示信息
    @State var licenseHint: String = ""
    // 是否正在获取许可证
    @State var acquiringLicense = false
    // 卡片动画状态
    @State var animateCards = false

    // 视图主体，定义界面布局
    var body: some View {
        ZStack {
            backgroundView
            mainContentView
            versionSelectorOverlay
        }
        .navigationTitle("APP详情")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            selection = eligibleAccounts.first?.id ?? .init()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateCards = true
            }
            loadVersions()
        }
    }
    
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color("#f0f4f8"), Color("#d9e2ec")]),
            startPoint: .top,
            endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all)
    }
    
    private var mainContentView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.lg) {
                packageHeaderCard
                
                if let error = versionError {
                    errorCard
                }
                
                pricingCard
                accountSelectorCard
                downloadButtonCard
                descriptionCard
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.lg)
        }
    }
    
    private var versionSelectorOverlay: some View {
        Group {
            if showingVersionSelector {
                versionSelectorBackground
                versionSelectorContent
            }
        }
    }
    
    private var versionSelectorBackground: some View {
        Color.black.opacity(0.5)
            .edgesIgnoringSafeArea(.all)
            .onTapGesture {
                showingVersionSelector = false
            }
    }
    
    private var versionSelectorContent: some View {
        VStack {
            Text("选择版本")
                .font(.headline)
                .padding()
            
            versionList
            
            Button("取消") {
                showingVersionSelector = false
            }
            .padding()
        }
        .scaleEffect(showingVersionSelector ? 1.0 : 0.8)
        .opacity(showingVersionSelector ? 1.0 : 0.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showingVersionSelector)
        .zIndex(1)
    }
    
    private var versionList: some View {
        ForEach(versions, id: \.id) { version in
            versionButton(for: version)
        }
    }
    
    private func versionButton(for version: VersionModels.AppVersion) -> some View {
        Button(action: {
            startDownloadWithVersion(version: version)
            showingVersionSelector = false
        }) {
            VStack(alignment: .leading) {
                Text(version.versionString)
                    .font(.body)
                Text(version.releaseDate?.formatted() ?? "未知日期")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // 加载版本信息的方法
    private func loadVersions() {
        guard !archive.bundleIdentifier.isEmpty else {
            return
        }
        
        loadingVersions = true
        versionError = nil
        
        // 使用合并的版本管理功能
        guard let account = account else {
            loadingVersions = false
            versionError = "需要选择账户"
            return
        }
        
        let request = VersionModels.VersionFetchRequest(
            appId: archive.bundleIdentifier,
            bundleId: archive.bundleIdentifier,
            region: region
        )
        
        Task {
            do {
                let response = try await fetchVersions(for: request, account: account)
                await MainActor.run {
                    self.versions = response.versions
                    self.loadingVersions = false
                }
            } catch {
                await MainActor.run {
                    self.versionError = "加载版本失败: \(error.localizedDescription)"
                    self.loadingVersions = false
                }
            }
        }
    }
    
    // 开始下载APP
    private func startDownload() {
        guard let account = account else {
            hint = "请选择一个账户"
            return
        }
        
        // 如果有多个版本，显示版本选择器
        if versions.count > 1 {
            showingVersionSelector = true
            return
        }
        
        // 如果只有一个版本或没有版本信息，直接下载
        obtainDownloadURL = true
        hint = ""
        
        Task {
            do {
                // TODO: 实现真实的下载请求逻辑
                print("开始下载: \(archive.bundleIdentifier)")
                
                DispatchQueue.main.async {
                    obtainDownloadURL = false
                    hint = "Requested \(archive.name)"
                }
            } catch {
                DispatchQueue.main.async {
                    obtainDownloadURL = false
                    hint = error.localizedDescription
                }
            }
        }
    }
    
    // 使用指定版本开始下载
    private func startDownloadWithVersion(version: VersionModels.AppVersion) {
        guard let account = account else {
            hint = "请选择一个账户"
            return
        }
        
        obtainDownloadURL = true
        hint = ""
        showingVersionSelector = false
        
        Task {
            do {
                // TODO: 实现真实的指定版本下载逻辑
                throw VersionError.noVersionsAvailable
            } catch {
                DispatchQueue.main.async {
                    obtainDownloadURL = false
                    hint = error.localizedDescription
                }
            }
        }
    }
    
    // 获取许可证
    private func acquireLicense() {
        guard let account = account else {
            licenseHint = "请先选择账户"
            return
        }
        
        acquiringLicense = true
        licenseHint = "正在获取许可证..."
        
        Task {
            do {
                // TODO: 实现真实的许可证获取逻辑
                throw VersionError.downloadFailed("下载功能暂未实现")
            } catch {
                DispatchQueue.main.async {
                    acquiringLicense = false
                    licenseHint = error.localizedDescription
                }
            }
        }
    }

    // APP头部卡片视图
    var packageHeaderCard: some View {
        // 现代卡片样式容器
        ModernCard(style: .elevated, padding: Spacing.lg) {
            // 垂直排列视图
            VStack(alignment: .leading, spacing: Spacing.md) {
                // 水平排列视图
                HStack(alignment: .top, spacing: Spacing.md) {
                    // APP图标
                    KFImage(URL(string: archive.artworkUrl512 ?? ""))
                        .antialiased(true)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .cornerRadius(16)
                        .modernCardStyle()
                    
                    // 垂直排列APP基本信息
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        // APP名称
                        Text(archive.name)
                            .font(.title2)
                            .foregroundColor(.primary)
                        
                        // APPBundle标识符
                        Label {
                            Text(archive.bundleIdentifier)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "app.badge")
                                .foregroundColor(Color.secondaryAccent)
                        }
                        
                        // APP版本和大小信息
                        Label {
                            Text("\(archive.version) • \(archive.byteCountDescription)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: archive.displaySupportedDevicesIcon)
                                .foregroundColor(Color.primaryAccent)
                        }
                    }
                    
                    // 占位符，使内容靠左对齐
                    Spacer()
                }
                
                // 如果有更新内容，则显示更新信息
                if let releaseNote = archive.releaseNotes {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Label("更新内容", systemImage: "sparkles")
                            .font(.subheadline)
                            .foregroundColor(Color.primaryAccent)
                        
                        Text(releaseNote)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .lineLimit(4)
                    }
                }
            }
        }
    }

    // 错误卡片视图
    var errorCard: some View {
        // 现代卡片样式容器
        ModernCard(style: .filled, padding: Spacing.md) {
            // 垂直排列视图
            VStack(spacing: Spacing.sm) {
                // 水平排列错误提示标题
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("需要账户")
                        .font(.headline)
                    Spacer()
                }
                
                // 错误提示详情
                Text("此地区没有可用账户。请在账户页面账户。")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        // 橙色边框
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.orange, lineWidth: 1)
        )
    }

    // 价格卡片视图
    var pricingCard: some View {
        // 现代卡片样式容器
        ModernCard(style: .elevated, padding: Spacing.lg) {
            // 垂直排列视图
            VStack(alignment: .leading, spacing: Spacing.md) {
                // 水平排列价格标题和货币信息
                HStack {
                    Label("价格", systemImage: "creditcard")
                        .font(.headline)
                        .foregroundColor(Color.primaryAccent)
                    
                    Spacer()
                    
                    Text(archive.currency ?? "USD")
                        .font(.caption)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(Color.secondaryAccent.opacity(0.1))
                        .foregroundColor(Color.secondaryAccent)
                        .cornerRadius(6)
                }
                
                // 显示APP格式化后的价格
                Text(archive.formattedPrice ?? "未知")
                    .font(.title2)
                    .foregroundColor(.primary)
                
                // 如果APP免费，则显示获取许可证按钮
                if let price = archive.price, price.isZero {
                    ModernButton(
                        style: .secondary,
                        size: .medium,
                        isDisabled: acquiringLicense || account == nil
                    ) {
                        acquireLicense()
                    } label: {
                        HStack {
                            if acquiringLicense {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "key.fill")
                            }
                            Text(acquiringLicense ? "获取中..." : "获取许可证")
                        }
                    }
                }
                
                // 如果有许可证提示信息，则显示提示，否则显示默认说明
                if !licenseHint.isEmpty {
                    Text(licenseHint)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.top, Spacing.xs)
                } else {
                    Text("付费APP无法获取许可证。如需要请先从App Store购买。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // 账户选择卡片视图
    var accountSelectorCard: some View {
        // 现代卡片样式容器
        ModernCard(style: .elevated, padding: Spacing.lg) {
            // 垂直排列视图
            VStack(alignment: .leading, spacing: Spacing.md) {
                // 水平排列账户选择标题和地区信息
                HStack {
                    Label("账户选择", systemImage: "person.circle")
                        .font(.headline)
                        .foregroundColor(Color.primaryAccent)
                    
                    Spacer()
                    
                    Text(region)
                        .font(.caption)
                        .padding(.horizontal, Spacing.sm)
                        .padding(.vertical, Spacing.xs)
                        .background(Color.primaryAccent.opacity(0.1))
                        .foregroundColor(Color.primaryAccent)
                        .cornerRadius(6)
                }
                
                // 根据不同状态显示不同内容
                if vm.demoMode {
                    Text("demo@example.com")
                        .font(.body)
                        .redacted(reason: .placeholder)
                } else if eligibleAccounts.isEmpty {
                    Text("地区 \(region) 没有可用账户")
                        .font(.body)
                        .foregroundColor(.secondary)
                } else {
                    // 账户选择菜单
                    Menu {
                        // 遍历符合条件的账户
                        ForEach(eligibleAccounts) { account in
                            Button(action: {
                                withAnimation(.easeInOut) {
                                    selection = account.id
                                }
                            }) {
                                HStack {
                                    Text(account.email)
                                    if selection == account.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("选择的账户")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(account?.email ?? "选择账户")
                                    .font(.body)
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down")
                                .foregroundColor(Color.primaryAccent)
                        }
                        .padding(Spacing.sm)
                        .background(Color.surfaceSecondary)
                        .cornerRadius(8)
                    }
                }
            }
        }
    }

    // 下载按钮卡片视图
    var downloadButtonCard: some View {
        // 现代卡片样式容器
        ModernCard(style: .elevated, padding: Spacing.lg) {
            // 垂直排列视图
            VStack(alignment: .leading, spacing: Spacing.md) {
                // 下载标题
                Label("下载", systemImage: "arrow.down.circle")
                    .font(.headline)
                    .foregroundColor(Color.primaryAccent)
                
                // 如果已有下载请求，则显示跳转链接，否则显示下载按钮
                if let req = dvm.downloadRequest(forArchive: archive) {
                    NavigationLink(destination: PackageView(request: req)) {
                        HStack {
                            Image(systemName: "doc.badge.arrow.up")
                            Text("显示下载")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(Color.primaryAccent)
                        .padding(Spacing.sm)
                        .background(Color.primaryAccent.opacity(0.1))
                        .cornerRadius(8)
                    }
                } else {
                    VStack(spacing: Spacing.sm) {
                        // 主下载按钮
                        ModernButton(
                            style: .primary,
                            size: .large,
                            isDisabled: obtainDownloadURL || account == nil
                        ) {
                            startDownload()
                        } label: {
                            HStack {
                                if obtainDownloadURL {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "arrow.down.circle.fill")
                                }
                                Text(obtainDownloadURL ? "正在与Apple通信..." : "下载最新版本")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                        // 版本选择按钮
                        if !versions.isEmpty {
                            ModernButton(
                                style: .secondary,
                                size: .medium,
                                isDisabled: loadingVersions || account == nil
                            ) {
                                showingVersionSelector = true
                            } label: {
                                HStack {
                                    if loadingVersions {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "clock.arrow.circlepath")
                                    }
                                    Text(loadingVersions ? "加载版本中..." : "选择历史版本 (\(versions.count))")
                                }
                                .frame(maxWidth: .infinity)
                            }
                        } else if loadingVersions {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("正在加载版本信息...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.xs)
                        }
                    }
                }
                
                // 如果有提示信息，则显示提示，否则显示默认说明
                if !hint.isEmpty {
                    Text(hint)
                        .font(.caption)
                        .foregroundColor(hint.contains("Requested") ? .green : .red)
                        .padding(.top, Spacing.xs)
                } else {
                    Text("软件包稍后可在下载页面安装。")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // 描述卡片视图
    var descriptionCard: some View {
        // 现代卡片样式容器
        ModernCard(style: .elevated, padding: Spacing.lg) {
            // 垂直排列视图
            VStack(alignment: .leading, spacing: Spacing.md) {
                // 描述标题
                Label("描述", systemImage: "doc.text")
                    .font(.headline)
                    .foregroundColor(Color.primaryAccent)
                
                // APP描述内容
                Text(archive.description ?? "未提供描述")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
                
                // 兼容性信息
                Divider()
                
                HStack {
                    Image(systemName: "iphone.gen10")
                        .foregroundColor(Color.primaryAccent)
                    Text("兼容性: iOS 15.0 或更高版本")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 开发者信息
                HStack {
                    Image(systemName: "person")
                        .foregroundColor(Color.secondaryAccent)
                    Text("开发者: \(archive.artistName ?? "未知")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // 发布日期信息
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(Color.secondaryAccent)
                    Text("发布日期: 未知")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// APP信息结构体，用于传递给版本选择器
struct AppInfo {
    let trackId: Int
    let trackName: String?
    let artistName: String?
    let bundleId: String?
    let artworkUrl512: String?
}

// 扩展String类型，提供字节计数格式化
extension String {
    static func formatByteCount(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// 扩展iTunesResponse.iTunesArchive，提供便捷属性
extension iTunesResponse.iTunesArchive {
    var byteCountDescription: String {
        if let byteSize = fileSizeBytes {
             return String.formatByteCount(Int64(byteSize) ?? 0)
        } else {
            return "未知"
        }
    }
    
    var displaySupportedDevicesIcon: String {
        if supportedDevices?.contains(where: { $0.contains("iPad") }) == true {
            return "ipad.and.iphone"
        } else {
            return "iphone.gen10"
        }
    }
    
    var formattedPrice: String? {
        if let price = price {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = currency
            return formatter.string(from: NSNumber(value: price))
        } else {
            return nil
        }
    }
}

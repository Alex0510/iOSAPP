//
//  ProductView.swift
//  Created by pxx917144686 on 2025/08/19.
//

import ApplePackage
import Kingfisher
import SwiftUI
import Backend.Downloader // 调整导入路径
import Interface.Download // 调整导入路径

// 搜索视图，显示APP的详细信息
struct ProductView: View {
    // 要显示的APP归档信息
    let archive: iTunesResponse.iTunesArchive
    // 地区代码
    let region: String

    // 账户状态管理对象
    @StateObject var vm = AppStore.this
    // 下载状态管理对象
    @StateObject var dvm = Downloads.this
    // 版本管理对象
    @StateObject private var versionManager = VersionManager()
    // 是否显示版本选择器
    @State private var showingVersionSelector = false
    // 版本列表
    @State private var versions: [VersionModels.AppVersion] = []
    // 加载版本列表的状态
    @State private var loadingVersions = false
    // 版本选择错误信息
    @State private var versionError: String?

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
            // 背景渐变
            LinearGradient(gradient: Gradient(colors: [Color("#f0f4f8"), Color("#d9e2ec")]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)

            // 垂直滚动视图
            ScrollView(.vertical, showsIndicators: false) {
                // 垂直排列视图
                VStack(spacing: Spacing.lg) {
                    // APP头部卡片，动画效果
                    packageHeaderCard

                    // 错误信息卡片，条件显示
                    if let error = versionError {
                        errorCard
                    }

                    // 价格卡片
                    pricingCard

                    // 账户选择卡片
                    accountSelectorCard

                    // 下载按钮卡片
                    downloadButtonCard

                    // 描述卡片
                    descriptionCard
                }
                // 设置内边距
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.lg)
            }

            // 版本选择器覆盖层
            if showingVersionSelector {
                // 半透明背景
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showingVersionSelector = false
                    }

                // 版本选择器视图
                VersionSelectorView(
                    appInfo: AppInfo(
                        trackId: archive.identifier,
                        trackName: archive.name,
                        artistName: archive.artistName,
                        bundleId: archive.bundleIdentifier,
                        artworkUrl512: archive.artworkUrl512
                    ),
                    versions: versions,
                    onVersionSelected: { version in
                        startDownloadWithVersion(version: version)
                    },
                    onCancel: {
                        showingVersionSelector = false
                    }
                )
                .transition(.scale)
                .zIndex(1)
            }
        }
        .navigationTitle("APP详情")
        .navigationBarTitleDisplayMode(.large)
        // 视图出现时的操作
        .onAppear {
            // 尝试获取第一个符合条件的账户来初始化版本管理器
            if let account = AppStore.this.accounts.first(where: { $0.countryCode == region }) {
                self.versionManager = VersionManager(appleId: account.email, password: account.password)
            } else {
                self.versionManager = nil
            }
            
            // 设置默认选中的账户ID
            selection = eligibleAccounts.first?.id ?? .init()
            
            // 延迟0.1秒后启动卡片动画
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateCards = true
            }
        }
    
    // 加载版本信息的方法
    private func loadVersions() {
        guard let account = account else {
            versionError = "请先选择一个账户"
            return
        }
        
        loadingVersions = true
        versionError = nil
        
        let request = VersionModels.VersionFetchRequest(
            appId: String(archive.identifier),
            forceRefresh: false
        )
        
        versionManager.fetchVersionsWithRetry(
            request: request,
            using: account,
            maxRetries: 3
        ) { result in
            DispatchQueue.main.async {
                self.loadingVersions = false
                
                switch result {
                case .success(let response):
                    self.versions = response.versions
                    self.versionError = nil
                    print("✅ 成功加载 \(response.versions.count) 个版本")
                case .failure(let error):
                    self.versionError = error.localizedDescription
                    print("❌ 加载版本失败: \(error)")
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
                let request = try await Downloader.this.requestDownload(
                    archive: archive,
                    account: account
                )
                
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
                // 创建版本下载请求
                let versionRequest = VersionModels.VersionDownloadRequest(
                    appId: String(archive.identifier),
                    versionId: version.id,
                    version: version
                )
                
                // 这里需要实现使用指定版本ID的下载逻辑
                // 目前先使用普通下载，后续需要扩展Downloader以支持版本选择
                let request = try await Downloader.this.requestDownload(
                    archive: archive,
                    account: account
                )
                
                DispatchQueue.main.async {
                    obtainDownloadURL = false
                    hint = "Requested \(archive.name) (版本: \(version.versionString))"
                }
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
                try await AppStore.this.acquireLicense(for: archive, account: account)
                DispatchQueue.main.async {
                    acquiringLicense = false
                    licenseHint = "许可证获取成功"
                }
            } catch {
                DispatchQueue.main.async {
                    acquiringLicense = false
                    licenseHint = error.localizedDescription
                }
            }
        }
    }
    
    // 视图主体，定义界面布局
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(gradient: Gradient(colors: [Color("#f0f4f8"), Color("#d9e2ec")]), startPoint: .top, endPoint: .bottom)
                .edgesIgnoringSafeArea(.all)

            // 垂直滚动视图
            ScrollView(.vertical, showsIndicators: false) {
                // 垂直排列视图
                VStack(spacing: Spacing.lg) {
                    // APP头部卡片，动画效果
                    packageHeaderCard
                        .scaleEffect(animateCards ? 1 : 0.9)
                        .opacity(animateCards ? 1 : 0)
                        .animation(.spring().delay(0.1), value: animateCards)
                    
                    // 错误信息卡片，条件显示
                    if let error = versionError {
                        errorCard
                            .scaleEffect(animateCards ? 1 : 0.9)
                            .opacity(animateCards ? 1 : 0)
                            .animation(.spring().delay(0.2), value: animateCards)
                    } else if account == nil {
                        errorCard
                            .scaleEffect(animateCards ? 1 : 0.9)
                            .opacity(animateCards ? 1 : 0)
                            .animation(.spring().delay(0.2), value: animateCards)
                    }
                    
                    // 价格卡片
                    pricingCard
                        .scaleEffect(animateCards ? 1 : 0.9)
                        .opacity(animateCards ? 1 : 0)
                        .animation(.spring().delay(0.3), value: animateCards)
                    
                    // 账户选择卡片
                    accountSelectorCard
                        .scaleEffect(animateCards ? 1 : 0.9)
                        .opacity(animateCards ? 1 : 0)
                        .animation(.spring().delay(0.4), value: animateCards)
                    
                    // 下载按钮卡片
                    downloadButtonCard
                        .scaleEffect(animateCards ? 1 : 0.9)
                        .opacity(animateCards ? 1 : 0)
                        .animation(.spring().delay(0.5), value: animateCards)
                    
                    // 描述卡片
                    descriptionCard
                        .scaleEffect(animateCards ? 1 : 0.9)
                        .opacity(animateCards ? 1 : 0)
                        .animation(.spring().delay(0.6), value: animateCards)
                }
                // 设置内边距
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.lg)
            }

            // 版本选择器覆盖层
            if showingVersionSelector {
                // 半透明背景
                Color.black.opacity(0.5)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        showingVersionSelector = false
                    }

                // 版本选择器视图
                VersionSelectorView(
                    appInfo: AppInfo(
                        trackId: archive.identifier,
                        trackName: archive.name,
                        artistName: archive.artistName,
                        bundleId: archive.bundleIdentifier,
                        artworkUrl512: archive.artworkUrl512
                    ),
                    versions: versions,
                    onVersionSelected: { version in
                        startDownloadWithVersion(version: version)
                    },
                    onCancel: {
                        showingVersionSelector = false
                    }
                )
                .transition(.scale)
                .zIndex(1)
            }
        }
        .navigationTitle("APP详情")
        .navigationBarTitleDisplayMode(.large)
        // 视图出现时的操作
        .onAppear {
            // 设置默认选中的账户ID
            selection = eligibleAccounts.first?.id ?? .init()
            
            // 延迟0.1秒后启动卡片动画
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateCards = true
            }
            
            // 加载版本信息
            loadVersions()
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
                            Text(obtainDownloadURL ? "正在与Apple通信..." : "请求下载")
                        }
                        .frame(maxWidth: .infinity)
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
    
        // APP描述内容
        Text(archive.description)
            .font(.body)
            .foregroundColor(.secondary)
            .lineLimit(nil)
    
        // 兼容性信息
        Divider()
    
        HStack {
            Image(systemName: "iphone.gen10")
                .foregroundColor(Color.primaryAccent)
            Text("兼容性: iOS \(archive.minimumOsVersion) 或更高版本")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    
        // 开发商信息
        HStack {
            Image(systemName: "person")
                .foregroundColor(Color.secondaryAccent)
            Text("开发商: \(archive.artistName)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    
        // 发布日期信息
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(Color.secondaryAccent)
            Text("发布日期: \(archive.releaseDate.formatted())")
                .font(.caption)
                .foregroundColor(.secondary)
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
        if let byteSize = fileSize {
            return String.formatByteCount(Int64(byteSize))
        } else {
            return "未知"
        }
    }
    
    var displaySupportedDevicesIcon: String {
        if supportedDevices.contains(where: { $0.contains("iPad") }) {
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
                    .foregroundColor(Color.primaryAccent)
                
                // 显示APP描述
                Text(archive.description ?? "未提供描述")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
        }
    }

    // 开始下载操作
    func startDownload() {
        // 检查账户是否存在
        guard let account else { return }
        // 检查版本管理器是否存在
        guard let versionManager else {
            hint = NSLocalizedString("无法初始化版本管理器，请确保账户有效。", comment: "")
            return
        }

        // 开始获取版本列表
        loadingVersions = true
        versionError = nil

        // 获取版本列表
        Task {
            do {
                let versionIDs = try await versionManager.getVersionIDs(appId: String(archive.identifier))
                DispatchQueue.main.async {
                    loadingVersions = false
                    if versionIDs.isEmpty {
                        versionError = NSLocalizedString("未找到该APP的历史版本。", comment: "")
                    } else {
                        versions = versionIDs
                        showingVersionSelector = true
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    loadingVersions = false
                    versionError = error.localizedDescription
                }
            }
        }
    }

    // 选择版本后开始下载
    private func startDownloadWithVersion(versionId: String) {
        // 检查账户是否存在
        guard let account else { return }
        // 标记正在获取下载URL
        obtainDownloadURL = true
        showingVersionSelector = false
        // 在全局队列异步执行网络请求
        DispatchQueue.global().async {
            let httpClient = HTTPClient(urlSession: URLSession.shared)
        let itunesClient = iTunesClient(httpClient: httpClient)
        let storeClient = StoreClient(httpClient: httpClient)
        // 使用选中的版本ID

            // 查找APP信息
            itunesClient.lookup(
                type: archive.entityType ?? .iPhone,
                bundleIdentifier: archive.bundleIdentifier,
                region: account.countryCode
            ) { result in
                switch result {
                case .success(let app):
                    do {
                        // 获取APP项目信息（使用选中的版本ID）
                        let item = try storeClient.item(
                            identifier: String(app.identifier),
                            directoryServicesIdentifier: account.storeResponse.directoryServicesIdentifier,
                            versionId: versionId
                        )
                        // 下载请求
                        let id = Downloads.this.add(request: .init(
                            account: account,
                            package: archive,
                            item: item
                        ))
                        // 恢复下载
                        Downloads.this.resume(requestID: id)
                        // 在主线程更新UI
                        DispatchQueue.main.async {
                            obtainDownloadURL = false
                            hint = NSLocalizedString("Download Requested", comment: "")
                        }
                    } catch {
                        // 在主线程更新UI，处理错误
                        DispatchQueue.main.async {
                            obtainDownloadURL = false
                            if (error as NSError).code == 9610 {
                                hint = NSLocalizedString("License Not Found, please acquire license first.", comment: "")
                            } else if (error as NSError).code == 2034 {
                                hint = NSLocalizedString("Password Token Expired, please re-authenticate within account page.", comment: "")
                            } else if (error as NSError).code == 2059 {
                                hint = NSLocalizedString("Temporarily Unavailable, please try again later.", comment: "")
                            } else {
                                hint = NSLocalizedString("Unable to retrieve download url, please try again later.", comment: "") + "\n" + error.localizedDescription
                            }
                        }
                    }
                case .failure(let error):
                    // 在主线程更新UI，处理错误
                    DispatchQueue.main.async {
                        obtainDownloadURL = false
                        if (error as NSError).code == 9610 {
                            hint = NSLocalizedString("License Not Found, please acquire license first.", comment: "")
                        } else if (error as NSError).code == 2034 {
                            hint = NSLocalizedString("Password Token Expired, please re-authenticate within account page.", comment: "")
                        } else if (error as NSError).code == 2059 {
                            hint = NSLocalizedString("Temporarily Unavailable, please try again later.", comment: "")
                        } else {
                            hint = NSLocalizedString("Unable to retrieve download url, please try again later.", comment: "") + "\n" + error.localizedDescription
                        }
                    }
                }
            }
        }
    }

    // 获取许可证操作
    private func acquireLicense() {
        // 检查账户是否存在
        guard let account else { return }
        // 标记正在获取许可证
        acquiringLicense = true
        // 在全局队列异步执行网络请求
        DispatchQueue.global().async {
            do {
                // 轮换密码令牌
                guard let account = try AppStore.this.rotate(id: account.id) else {
                    throw NSError(domain: "AppStore", code: 401, userInfo: [
                        NSLocalizedDescriptionKey: NSLocalizedString(
                            "Failed to rotate password token, please re-authenticate within account page.",
                            comment: ""
                        ),
                    ])
                }
                // 尝试购买APP以获取许可证
                try ApplePackage.purchase(
                    token: account.storeResponse.passwordToken,
                    directoryServicesIdentifier: account.storeResponse.directoryServicesIdentifier,
                    trackID: archive.identifier,
                    countryCode: account.countryCode
                )
                // 在主线程更新UI
                DispatchQueue.main.async {
                    acquiringLicense = false
                    licenseHint = NSLocalizedString("Request Successes", comment: "")
                }
            } catch {
                // 在主线程更新UI，处理错误
                DispatchQueue.main.async {
                    acquiringLicense = false
                    licenseHint = error.localizedDescription
                }
            }
        }
    }
}

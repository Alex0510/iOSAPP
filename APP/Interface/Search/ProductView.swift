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
    // 下载状态管理对象
    @StateObject var dvm = Downloads.this
    // 版本管理对象
    @StateObject private var versionManager: VersionManager
    // 是否显示版本选择器
    @State private var showingVersionSelector = false
    // 版本列表
    @State private var versions: [AppVersion] = []
    // 加载版本列表的状态
    @State private var loadingVersions = false
    // 版本选择错误信息
    @State private var versionError: String?

    // 初始化方法
    init(archive: iTunesResponse.iTunesArchive, region: String) {
        self.archive = archive
        self.region = region
        // 初始化版本管理器时需要一个默认账户，这里先用空的初始化
        self._versionManager = StateObject(wrappedValue: VersionManager())
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
                VStack {
                    Text("选择版本")
                        .font(.headline)
                        .padding()
                    
                    ForEach(versions, id: \.id) { version in
                        Button(action: {
                            startDownloadWithVersion(version: version)
                            showingVersionSelector = false
                        }) {
                            VStack(alignment: .leading) {
                                Text(version.versionString)
                                    .font(.body)
                                Text(version.releaseDate.formatted())
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
    }
    
    // 加载版本信息的方法
    private func loadVersions() {
        guard let account = account else {
            versionError = "请先选择一个账户"
            return
        }
        
        loadingVersions = true
        versionError = nil
        
        Task {
            do {
                let fetchedVersions = try await versionManager.getVersions(appId: String(archive.identifier))
                await MainActor.run {
                    self.loadingVersions = false
                    self.versions = fetchedVersions
                    self.versionError = nil
                    print("✅ 成功加载 \(fetchedVersions.count) 个版本")
                }
            } catch {
                await MainActor.run {
                    self.loadingVersions = false
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
                // 模拟下载请求
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
    private func startDownloadWithVersion(version: AppVersion) {
        guard let account = account else {
            hint = "请选择一个账户"
            return
        }
        
        obtainDownloadURL = true
        hint = ""
        showingVersionSelector = false
        
        Task {
            do {
                // 模拟指定版本下载请求
                print("开始下载版本 \(version.versionString): \(archive.bundleIdentifier)")
                
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
                // 模拟获取许可证的操作
                try await Task.sleep(nanoseconds: 1_000_000_000) // 模拟网络延迟
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
                    Text("兼容性: iOS 13.0 或更高版本")
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

// 应用版本信息
struct AppVersion: Identifiable, Codable {
    let id: String
    let versionString: String
    let releaseDate: Date
    let releaseNotes: String?
    let bundleVersion: String?
    
    init(id: String, versionString: String, releaseDate: Date = Date(), releaseNotes: String? = nil, bundleVersion: String? = nil) {
        self.id = id
        self.versionString = versionString
        self.releaseDate = releaseDate
        self.releaseNotes = releaseNotes
        self.bundleVersion = bundleVersion
    }
}

// 版本管理器，负责获取和管理应用的历史版本信息
@MainActor
class VersionManager: ObservableObject {
    @Published var isLoading = false
    @Published var error: String?
    
    init() {}
    
    // 获取应用的版本ID列表
    func getVersionIDs(appId: String) async throws -> [String] {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                self.isLoading = true
                self.error = nil
            }
            
            // 模拟获取版本列表的过程
            DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
                // 这里应该调用实际的API来获取版本列表
                // 目前返回模拟数据
                let mockVersions = [
                    "1001", "1002", "1003", "1004", "1005"
                ]
                
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                
                continuation.resume(returning: mockVersions)
            }
        }
    }
    
    // 获取应用的详细版本信息
    func getVersions(appId: String) async throws -> [AppVersion] {
        let versionIDs = try await getVersionIDs(appId: appId)
        
        // 将版本ID转换为详细的版本信息
        let versions = versionIDs.enumerated().map { index, versionId in
            AppVersion(
                id: versionId,
                versionString: "\(index + 1).0.\(index)",
                releaseDate: Calendar.current.date(byAdding: .day, value: -index * 30, to: Date()) ?? Date(),
                releaseNotes: "Version \(index + 1) release notes",
                bundleVersion: "\(index + 1).0.\(index).\(index * 10)"
            )
        }
        
        return versions
    }
}

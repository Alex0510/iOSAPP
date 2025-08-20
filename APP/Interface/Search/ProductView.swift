//
//  ProductView.swift
//  Created by pxx917144686 on 2025/08/19.
//

import ApplePackage
import Kingfisher
import SwiftUI

// 产品视图，显示应用的详细信息
struct ProductView: View {
    // 要显示的应用归档信息
    let archive: iTunesResponse.iTunesArchive
    // 地区代码
    let region: String

    // 账户状态管理对象
    @StateObject var vm = AppStore.this
    // 下载状态管理对象
    @StateObject var dvm = Downloads.this

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
        // 垂直滚动视图
        ScrollView(.vertical, showsIndicators: false) {
            // 垂直排列视图
            VStack(spacing: Spacing.lg) {
                // 应用头部卡片，添加动画效果
                packageHeaderCard
                    .scaleEffect(animateCards ? 1 : 0.9)
                    .opacity(animateCards ? 1 : 0)
                    .animation(.spring().delay(0.1), value: animateCards)
                
                // 错误卡片（如果需要），添加动画效果
                if account == nil {
                    errorCard
                        .scaleEffect(animateCards ? 1 : 0.9)
                        .opacity(animateCards ? 1 : 0)
                        .animation(.spring().delay(0.2), value: animateCards)
                }
                
                // 价格卡片，添加动画效果
                pricingCard
                    .scaleEffect(animateCards ? 1 : 0.9)
                    .opacity(animateCards ? 1 : 0)
                    .animation(.spring().delay(0.3), value: animateCards)
                
                // 账户选择卡片，添加动画效果
                accountSelectorCard
                    .scaleEffect(animateCards ? 1 : 0.9)
                    .opacity(animateCards ? 1 : 0)
                    .animation(.spring().delay(0.4), value: animateCards)
                
                // 下载按钮卡片，添加动画效果
                downloadButtonCard
                    .scaleEffect(animateCards ? 1 : 0.9)
                    .opacity(animateCards ? 1 : 0)
                    .animation(.spring().delay(0.5), value: animateCards)
                
                // 描述卡片，添加动画效果
                descriptionCard
                    .scaleEffect(animateCards ? 1 : 0.9)
                    .opacity(animateCards ? 1 : 0)
                    .animation(.spring().delay(0.6), value: animateCards)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.lg)
        }
        .navigationTitle("应用详情")
        .navigationBarTitleDisplayMode(.large)
        // 视图出现时的操作
        .onAppear {
            // 设置默认选中的账户ID
            selection = eligibleAccounts.first?.id ?? .init()
            // 延迟0.1秒后启动卡片动画
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateCards = true
            }
        }
    }

    // 应用头部卡片视图
    var packageHeaderCard: some View {
        // 现代卡片样式容器
        ModernCard(style: .elevated, padding: Spacing.lg) {
            // 垂直排列视图
            VStack(alignment: .leading, spacing: Spacing.md) {
                // 水平排列视图
                HStack(alignment: .top, spacing: Spacing.md) {
                    // 应用图标
                    KFImage(URL(string: archive.artworkUrl512 ?? ""))
                        .antialiased(true)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .cornerRadius(16)
                        .modernCardStyle()
                    
                    // 垂直排列应用基本信息
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        // 应用名称
                        Text(archive.name)
                            .font(.title2)
                            .foregroundColor(.primary)
                        
                        // 应用Bundle标识符
                        Label {
                            Text(archive.bundleIdentifier)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "app.badge")
                                .foregroundColor(Color.secondaryAccent)
                        }
                        
                        // 应用版本和大小信息
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
                Text("此地区没有可用账户。请在账户页面添加账户。")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        // 添加橙色边框
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
                
                // 显示应用格式化后的价格
                Text(archive.formattedPrice ?? "未知")
                    .font(.title2)
                    .foregroundColor(.primary)
                
                // 如果应用免费，则显示获取许可证按钮
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
                    Text("付费应用无法获取许可证。如需要请先从App Store购买。")
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
                    .foregroundColor(Color.primaryAccent)
                
                // 显示应用描述
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
        // 标记正在获取下载URL
        obtainDownloadURL = true
        // 在全局队列异步执行网络请求
        DispatchQueue.global().async {
            let httpClient = HTTPClient(urlSession: URLSession.shared)
            let itunesClient = iTunesClient(httpClient: httpClient)
            let storeClient = StoreClient(httpClient: httpClient)

            // 查找应用信息
            itunesClient.lookup(
                type: archive.entityType ?? .iPhone,
                bundleIdentifier: archive.bundleIdentifier,
                region: account.countryCode
            ) { result in
                switch result {
                case .success(let app):
                    do {
                        // 获取应用项目信息
                        let item = try storeClient.item(
                            identifier: String(app.identifier),
                            directoryServicesIdentifier: account.storeResponse.directoryServicesIdentifier
                        )
                        // 添加下载请求
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
    func acquireLicense() {
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
                // 尝试购买应用以获取许可证
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

// 扩展iTunesResponse.iTunesArchive，添加显示支持设备图标的计算属性
extension iTunesResponse.iTunesArchive {
    var displaySupportedDevicesIcon: String {
        var supports_iPhone = false
        var supports_iPad = false
        // 遍历支持的设备列表
        for device in supportedDevices ?? [] {
            if device.lowercased().contains("iphone") {
                supports_iPhone = true
            }
            if device.lowercased().contains("ipad") {
                supports_iPad = true
            }
        }
        // 根据支持的设备类型返回对应的图标名称
        if supports_iPhone, supports_iPad {
            return "ipad.and.iphone"
        } else if supports_iPhone {
            return "iphone"
        } else if supports_iPad {
            return "ipad"
        } else {
            return "questionmark"
        }
    }
}

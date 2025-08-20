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

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: Spacing.lg) {
                // 应用头部卡片
                packageHeaderCard
                    .scaleEffect(animateCards ? 1 : 0.9)
                    .opacity(animateCards ? 1 : 0)
                    .animation(.spring().delay(0.1), value: animateCards)
                
                // 错误卡片（如果需要）
                if account == nil {
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
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.lg)
        }
        .navigationTitle("应用详情")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            selection = eligibleAccounts.first?.id ?? .init()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateCards = true
            }
        }
    }

    // 应用头部卡片视图
    var packageHeaderCard: some View {
        ModernCard(style: .elevated, padding: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(alignment: .top, spacing: Spacing.md) {
                    // 应用图标
                    KFImage(URL(string: archive.artworkUrl512 ?? ""))
                        .antialiased(true)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .cornerRadius(16)
                        .modernCardStyle()
                    
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(archive.name)
                            .font(.title2)
                            .foregroundColor(.primary)
                        
                        Label {
                            Text(archive.bundleIdentifier)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: "app.badge")
                                .foregroundColor(Color.secondaryAccent)
                        }
                        
                        Label {
                            Text("\(archive.version) • \(archive.byteCountDescription)")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        } icon: {
                            Image(systemName: archive.displaySupportedDevicesIcon)
                                .foregroundColor(Color.primaryAccent)
                        }
                    }
                    
                    Spacer()
                }
                
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
        ModernCard(style: .filled, padding: Spacing.md) {
            VStack(spacing: Spacing.sm) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("需要账户")
                        .font(.headline)
                    Spacer()
                }
                
                Text("此地区没有可用账户。请在账户页面添加账户。")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.orange, lineWidth: 1)
        )
    }

    // 价格卡片视图
    var pricingCard: some View {
        ModernCard(style: .elevated, padding: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.md) {
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
                
                Text(archive.formattedPrice ?? "未知")
                    .font(.title2)
                    .foregroundColor(.primary)
                
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

    var accountSelectorCard: some View {
        ModernCard(style: .elevated, padding: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.md) {
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
                
                if vm.demoMode {
                    Text("demo@example.com")
                        .font(.body)
                        .redacted(reason: .placeholder)
                } else if eligibleAccounts.isEmpty {
                    Text("地区 \(region) 没有可用账户")
                        .font(.body)
                        .foregroundColor(.secondary)
                } else {
                    Menu {
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

    var downloadButtonCard: some View {
        ModernCard(style: .elevated, padding: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Label("下载", systemImage: "arrow.down.circle")
                    .font(.headline)
                    .foregroundColor(Color.primaryAccent)
                
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

    var descriptionCard: some View {
        ModernCard(style: .elevated, padding: Spacing.lg) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Label("描述", systemImage: "doc.text")
                    .font(.headline)
                    .foregroundColor(Color.primaryAccent)
                
                Text(archive.description ?? "未提供描述")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            }
        }
    }

    func startDownload() {
        guard let account else { return }
        obtainDownloadURL = true
        DispatchQueue.global().async {
            let httpClient = HTTPClient(urlSession: URLSession.shared)
            let itunesClient = iTunesClient(httpClient: httpClient)
            let storeClient = StoreClient(httpClient: httpClient)

            itunesClient.lookup(
                type: archive.entityType ?? .iPhone,
                bundleIdentifier: archive.bundleIdentifier,
                region: account.countryCode
            ) { result in
                switch result {
                case .success(let app):
                    do {
                        let item = try storeClient.item(
                            identifier: String(app.identifier),
                            directoryServicesIdentifier: account.storeResponse.directoryServicesIdentifier
                        )
                        let id = Downloads.this.add(request: .init(
                            account: account,
                            package: archive,
                            item: item
                        ))
                        Downloads.this.resume(requestID: id)
                        DispatchQueue.main.async {
                            obtainDownloadURL = false
                            hint = NSLocalizedString("Download Requested", comment: "")
                        }
                    } catch {
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

    func acquireLicense() {
        guard let account else { return }
        acquiringLicense = true
        DispatchQueue.global().async {
            do {
                guard let account = try AppStore.this.rotate(id: account.id) else {
                    throw NSError(domain: "AppStore", code: 401, userInfo: [
                        NSLocalizedDescriptionKey: NSLocalizedString(
                            "Failed to rotate password token, please re-authenticate within account page.",
                            comment: ""
                        ),
                    ])
                }
                try ApplePackage.purchase(
                    token: account.storeResponse.passwordToken,
                    directoryServicesIdentifier: account.storeResponse.directoryServicesIdentifier,
                    trackID: archive.identifier,
                    countryCode: account.countryCode
                )
                DispatchQueue.main.async {
                    acquiringLicense = false
                    licenseHint = NSLocalizedString("Request Successes", comment: "")
                }
            } catch {
                DispatchQueue.main.async {
                    acquiringLicense = false
                    licenseHint = error.localizedDescription
                }
            }
        }
    }
}

extension iTunesResponse.iTunesArchive {
    var displaySupportedDevicesIcon: String {
        var supports_iPhone = false
        var supports_iPad = false
        for device in supportedDevices ?? [] {
            if device.lowercased().contains("iphone") {
                supports_iPhone = true
            }
            if device.lowercased().contains("ipad") {
                supports_iPad = true
            }
        }
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

import ApplePackage
import Combine
import SwiftUI
import Foundation


/// Muffin认证卡片视图
struct MuffinAuthenticationCard: View {
    var body: some View {
        VStack {
            Text("Muffin认证")
                .font(.headline)
            Text("请完成Muffin认证以继续")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// 下载视图，用于直接下载App Store中不再可用的应用
struct AddDownloadView: View {
    // 应用包ID
    @State var bundleID: String = ""
    // 搜索的实体类型（iPhone、iPad等）
    @State var searchType: EntityType = .iPhone
    // 选中的账户ID
    @State var selection: AppStore.Account.ID = .init()
    // 是否正在获取下载URL
    @State var obtainDownloadURL = false
    // 提示信息
    @State var hint = ""
    // 版本选择功能已移至SearchView.swift
    // @State var showVersionSelector = false
    // @State var currentApp: iTunesResponse.iTunesArchive?
    // @State var currentAccount: AppStore.Account?

    // 搜索框焦点状态
    @FocusState var searchKeyFocused

    // 账户状态管理对象
    @StateObject var avm = AppStore.this
    // 下载状态管理对象
    @StateObject var dvm = Downloads.this
    // MuffinStore集成管理器
    // MuffinIntegrationManager 已移至 SearchView.swift
    // @StateObject var muffinManager = MuffinIntegrationManager.shared

    // 用于关闭当前视图的环境变量
    @Environment(\.dismiss) var dismiss

    // 根据选中的ID获取账户对象
    var account: AppStore.Account? {
        avm.accounts.first { $0.id == selection }
    }

    var body: some View {
        // 使用List布局展示界面元素
        List {
            // MuffinStore集成状态卡片
            Section {
                MuffinAuthenticationCard()
            } header: {
                Text("MuffinStore 集成")
            } footer: {
                Text("登录后可下载应用的历史版本，获得更多下载选项。")
            }
            
            // 应用包ID相关输入区域
            Section {
                // 应用包ID输入框
                TextField("应用包ID", text: $bundleID)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.none)
                    .focused($searchKeyFocused)
                    .onSubmit { startDownload() }
                // 实体类型选择器
                Picker("实体类型", selection: $searchType) {
                    ForEach(EntityType.allCases, id: \.self) { type in
                        Text(type.rawValue)
                            .tag(type)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("应用包ID")
            } footer: {
                Text("告诉我们应用的包ID以启动直接下载。适用于下载App Store中不再可用的应用。")
            }

            // 账户选择区域
            Section {
                if avm.demoMode {
                    // 演示模式下显示隐藏内容
                    Text("演示模式已隐藏")
                        .redacted(reason: .placeholder)
                } else {
                    // 账户选择器
                    Picker("账户", selection: $selection) {
                        ForEach(avm.accounts) { account in
                            Text(account.email)
                                .id(account.id)
                        }
                    }
                    .pickerStyle(.menu)
                    .onAppear { selection = avm.accounts.first?.id ?? .init() }
                }
            } header: {
                Text("账户")
            } footer: {
                Text("选择一个账户来下载此应用")
            }

            // 请求下载按钮区域
            Section {
                // 请求下载按钮，根据状态显示不同文本
                Button(obtainDownloadURL ? "正在与Apple通信..." : "请求下载") {
                    startDownload()
                }
                .disabled(bundleID.isEmpty)
                .disabled(obtainDownloadURL)
                .disabled(account == nil)
            } footer: {
                if hint.isEmpty {
                    Text("软件包可稍后在下载页面中安装。")
                } else {
                    // 显示错误提示信息
                    Text(hint)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("直接下载")
    }
    
    // 使用标准方法下载应用
    private func downloadWithVersion(app: iTunesResponse.iTunesArchive, account: AppStore.Account, version: VersionModels.AppVersion?) async {
        do {
            // 使用Downloads直接下载最新版本
            print("🔄 使用标准方法下载最新版本")
            
            // 使用ApplePackage.Downloader进行下载
            let appleDownloader = ApplePackage.Downloader(
                email: account.email,
                directoryServicesIdentifier: account.storeResponse.directoryServicesIdentifier,
                region: account.countryCode
            )
            
            // 创建下载目录
            let downloadsDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            let appDirectory = downloadsDirectory.appendingPathComponent("APP123")
            try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
            
            // 生成文件名
            let fileName = "\(app.name)_\(app.version).ipa"
            
            // 执行下载
            let downloadedURL = try appleDownloader.download(
                type: searchType,
                bundleIdentifier: app.bundleIdentifier,
                saveToDirectory: appDirectory,
                withFileName: fileName
            )
            await MainActor.run {
                hint = "✅ 下载已开始"
            }
            
            print("✅ 下载完成，文件保存至: \(downloadedURL.path)")
            
            // 延迟关闭界面
            await MainActor.run {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    dismiss()
                }
            }
            
        } catch {
            await MainActor.run {
                hint = "❌ 下载失败: \(error.localizedDescription)"
                print("❌ 下载失败: \(error)")
            }
        }
    }
    
    // 开始下载的方法
    func startDownload() {
        // 检查账户是否存在
        guard let account else { return }
        // 取消搜索框焦点
        searchKeyFocused = false
        // 标记正在获取下载URL
        obtainDownloadURL = true
        // 在全局队列中执行网络请求
        DispatchQueue.global().async {
            // 创建HTTP客户端
            let httpClient = HTTPClient(urlSession: URLSession.shared)
            // 创建iTunes客户端
            let itunesClient = iTunesClient(httpClient: httpClient)
            // 创建商店客户端
            let storeClient = StoreClient(httpClient: httpClient)

            // 根据应用包ID查找应用信息
            itunesClient.lookup(
                type: searchType,
                bundleIdentifier: bundleID,
                region: account.countryCode
            ) { result in
                switch result {
                case .success(let app):
                    do {
                        // 获取应用商品信息
                        let item = try storeClient.item(
                            identifier: String(app.identifier),
                            directoryServicesIdentifier: account.storeResponse.directoryServicesIdentifier
                        )
                        
                        // 直接开始下载最新版本
                        Task {
                            await downloadWithVersion(app: app, account: account, version: nil)
                        }
                    } catch {
                        DispatchQueue.main.async {
                            // 请求失败，重置状态并显示错误信息
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
                        // 请求失败，重置状态并显示错误信息
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
}

import ApplePackage
import Combine
import SwiftUI

// 添加下载视图，用于直接下载App Store中不再可用的应用

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

    // 搜索框焦点状态
    @FocusState var searchKeyFocused

    // 账户状态管理对象
    @StateObject var avm = AppStore.this
    // 下载状态管理对象
    @StateObject var dvm = Downloads.this

    // 用于关闭当前视图的环境变量
    @Environment(\.dismiss) var dismiss

    // 根据选中的ID获取账户对象
    var account: AppStore.Account? {
        avm.accounts.first { $0.id == selection }
    }

    var body: some View {
        // 使用List布局展示界面元素
        List {
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

    // 显示版本选择视图
    private func showVersionSelector(app: iTunesResponse.iTunesArchive, account: AppStore.Account, item: StoreResponse.Item) {
        // 创建版本管理器实例
        let versionManager = VersionManager()
        
        // 使用Task异步获取版本信息
        Task {
            do {
                let versions = try await versionManager.getVersions(appId: String(app.identifier))
                await MainActor.run {
                    if let firstVersion = versions.first {
                        // 模拟下载请求
                        print("开始下载应用: \(app.name)")
                        hint = "下载请求已发送"
                        obtainDownloadURL = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            dismiss()
                        }
                    } else {
                        hint = "没有可用版本"
                        obtainDownloadURL = false
                    }
                }
            } catch {
                await MainActor.run {
                    hint = "获取版本失败: \(error.localizedDescription)"
                    obtainDownloadURL = false
                }
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
                        
                        // 在主线程显示版本选择器
                        DispatchQueue.main.async {
                            self.showVersionSelector(app: app, account: account, item: item)
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

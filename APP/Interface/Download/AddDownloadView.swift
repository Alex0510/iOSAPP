import ApplePackage
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
        List {
            Section {
                TextField("应用包ID", text: $bundleID)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.none)
                    .focused($searchKeyFocused)
                    .onSubmit { startDownload() }
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

            Section {
                if avm.demoMode {
                    Text("演示模式已隐藏")
                        .redacted(reason: .placeholder)
                } else {
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

            Section {
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
                    Text(hint)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("直接下载")
    }

    // 开始下载的方法
    func startDownload() {
        guard let account else { return }
        searchKeyFocused = false
        obtainDownloadURL = true
        DispatchQueue.global().async {
            let httpClient = HTTPClient(urlSession: URLSession.shared)
            let itunesClient = iTunesClient(httpClient: httpClient)
            let storeClient = StoreClient(httpClient: httpClient)

            itunesClient.lookup(
                type: searchType,
                bundleIdentifier: bundleID,
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
                            package: app,
                            item: item
                        ))
                        Downloads.this.resume(requestID: id)
                        DispatchQueue.main.async {
                            hint = NSLocalizedString("Download Requested", comment: "")
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            dismiss()
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
}

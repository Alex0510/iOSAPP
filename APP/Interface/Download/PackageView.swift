// 导入 ApplePackage 模块
import ApplePackage
// 导入 Kingfisher 库，用于图片加载
import Kingfisher
// 导入 SwiftUI 框架
import SwiftUI

// 定义一个名为 PackageView 的视图结构体
struct PackageView: View {
    // 存储下载请求信息
    let request: Downloads.Request
    // 从请求中获取 iTunes 归档信息
    var archive: iTunesResponse.iTunesArchive {
        request.package
    }

    // 获取请求的目标文件路径
    var url: URL { request.targetLocation }

    // 获取用于关闭当前视图的环境值
    @Environment(\.dismiss) var dismiss
    // 存储安装器实例
    @State var installer: Installer?
    // 存储错误信息
    @State var error: String = ""

    // 使用状态对象存储 AppStore 实例
    @StateObject var vm = AppStore.this

    // 视图的主体内容
    var body: some View {
        // 创建一个列表视图
        List {
            // 定义一个列表分区
            Section {
                // 创建一个垂直排列的视图容器
                VStack(alignment: .leading, spacing: 8) {
                    // 使用 Kingfisher 加载图片
                    KFImage(URL(string: archive.artworkUrl512 ?? ""))
                        .antialiased(true)  // 启用抗锯齿
                        .resizable()        // 允许图片调整大小
                        .cornerRadius(8)    // 设置圆角半径
                        .frame(width: 50, height: 50, alignment: .center)  // 设置固定大小
                        .frame(maxWidth: .infinity, alignment: .leading)    // 最大宽度并左对齐
                    // 显示归档名称
                    Text(archive.name)
                        .bold()  // 设置为粗体
                }
                .padding(.vertical, 4)  // 设置垂直内边距
            } header: {
                // 分区头部标题
                Text("Package")
            } footer: {
                // 分区底部显示包标识、版本和字节数描述
                Text("\(archive.bundleIdentifier) - \(archive.version) - \(archive.byteCountDescription)")
            }

            // 如果下载已完成
            if Downloads.shared.isCompleted(for: request) {
                // 定义一个列表分区
                Section {
                    // 创建一个安装按钮
                    Button("Install") {
                        do {
                            // 尝试创建安装器实例
                            installer = try Installer(archive: archive, path: url)
                        } catch {
                            // 捕获错误并存储错误信息
                            self.error = error.localizedDescription
                        }
                    }
                    .sheet(item: $installer) {
                        // 关闭 sheet 时销毁安装器实例
                        installer?.destroy()
                        installer = nil
                    } content: {
                        // 显示安装视图
                        InstallerView(installer: $0)
                    }

                    // 创建一个通过 AirDrop 安装的按钮
                    Button("Install via AirDrop") {
                        // 生成临时文件路径
                        let newUrl = temporaryDirectory
                            .appendingPathComponent("\(archive.bundleIdentifier)-\(archive.version)")
                            .appendingPathExtension("ipa")
                        // 尝试删除已存在的临时文件
                        try? FileManager.default.removeItem(at: newUrl)
                        // 尝试复制文件到临时路径
                        try? FileManager.default.copyItem(at: url, to: newUrl)
                        // 调用分享方法
                        share(items: [newUrl])
                    }
                } header: {
                    // 分区头部标题
                    Text("Control")
                } footer: {
                    if error.isEmpty {
                        // 没有错误时显示提示信息
                        Text("Direct install may have limitations that is not able to bypass. Use AirDrop method if possible on another device.")
                    } else {
                        // 有错误时显示错误信息
                        Text(error)
                            .foregroundStyle(.red)  // 设置错误信息为红色
                    }
                }
            } else {
                // 下载未完成时的分区
                Section {
                    // 根据下载状态显示不同内容
                    switch request.runtime.status {
                    case .stopped:
                        // 下载停止时显示继续下载按钮
                        Button("Continue Download") {
                            Downloads.shared.resume(request.id)
                        }
                    case .downloading,
                         .pending:
                        // 下载中或待处理时显示提示信息
                        Text("Download In Progress...")
                    case .verifying:
                        // 验证中时显示提示信息
                        Text("Verification In Progress...")
                    case .completed:
                        // 已完成（理论上不会进入这里），不显示内容
                        Group {}
                    }
                } header: {
                    // 分区头部标题
                    Text("Incomplete Package")
                } footer: {
                    // 根据下载状态显示不同的底部信息
                    switch request.runtime.status {
                    case .stopped:
                        // 下载停止时显示原因和提示
                        Text("Either connection is lost or the download is interrupted. Tap to continue.")
                    case .downloading,
                         .pending:
                        // 下载中或待处理时显示下载进度
                        Text("\(Int(request.runtime.percent * 100))%...")
                    case .verifying:
                        // 验证中时显示验证进度
                        Text("\(Int(request.runtime.percent * 100))%...")
                    case .completed:
                        // 已完成（理论上不会进入这里），不显示内容
                        Group {}
                    }
                }
            }

            // 定义账户信息分区
            Section {
                if vm.demoMode {
                    // 演示模式下显示占位文本
                    Text("88888888888")
                        .redacted(reason: .placeholder)  // 标记为占位文本
                } else {
                    // 非演示模式下显示账户邮箱
                    Text(request.account.email)
                }
                // 显示账户国家代码和对应的国家名称
                Text("\(request.account.countryCode) - \(ApplePackage.countryCodeMap[request.account.countryCode] ?? "-1")")
            } header: {
                // 分区头部标题
                Text("Account")
            } footer: {
                // 分区底部显示账户使用说明
                Text("This account is used to download this package. If you choose to AirDrop, your target device must sign in or previously signed in to this account and have at least one app installed.")
            }

            // 定义危险操作分区
            Section {
                // 创建删除按钮
                Button("Delete") {
                    // 删除下载请求
                    Downloads.shared.delete(request: request)
                    dismiss()
                }
                .foregroundStyle(.red)  // 设置按钮文本为红色
            } header: {
                // 分区头部标题
                Text("Danger Zone")
            } footer: {
                // 分区底部显示文件路径
                Text(url.path)
            }
        }
        .navigationTitle(request.package.name)  // 设置导航栏标题
    }

    // 可忽略返回值的分享方法
    @discardableResult
    func share(
        items: [Any],
        excludedActivityTypes: [UIActivity.ActivityType]? = nil
    ) -> Bool {
        // 获取当前最顶层的视图控制器
        guard let source = UIWindow.mainWindow?.rootViewController?.topMostController else {
            return false
        }
        // 创建一个新的视图
        let newView = UIView()
        // 将新视图添加到源视图上
        source.view.addSubview(newView)
        // 设置新视图的大小
        newView.frame = .init(origin: .zero, size: .init(width: 10, height: 10))
        // 设置新视图的中心位置
        newView.center = .init(
            x: source.view.bounds.width / 2 - 5,
            y: source.view.bounds.height / 2 - 5
        )
        // 创建一个活动视图控制器用于分享
        let vc = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        // 设置排除的活动类型
        vc.excludedActivityTypes = excludedActivityTypes
        // 设置弹出视图的源视图
        vc.popoverPresentationController?.sourceView = source.view
        // 设置弹出视图的源矩形
        vc.popoverPresentationController?.sourceRect = newView.frame
        // 呈现活动视图控制器
        source.present(vc, animated: true) {
            // 1 秒后移除新视图
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                newView.removeFromSuperview()
            }
        }
        return true
    }
}

// 扩展 UIWindow，添加获取主窗口的方法
extension UIWindow {
    static var mainWindow: UIWindow? {
        // 尝试通过 keyWindow 获取主窗口
        if let keyWindow = UIApplication
            .shared
            .value(forKey: "keyWindow") as? UIWindow
        {
            return keyWindow
        }
        // 如果上述方法不可用，使用另一种方式获取主窗口
        // if apple remove this shit, we fall back to ugly solution
        let keyWindow = UIApplication
            .shared
            .connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .filter(\.isKeyWindow)
            .first
        return keyWindow
    }
}

// 扩展 UIViewController，添加获取最顶层视图控制器的方法
extension UIViewController {
    var topMostController: UIViewController? {
        var result: UIViewController? = self
        while true {
            if let next = result?.presentedViewController,
               !next.isBeingDismissed,
               next as? UISearchController == nil
            {
                // 如果有正在呈现的视图控制器且不是正在被关闭的搜索控制器，则更新结果
                result = next
                continue
            }
            if let tabBar = result as? UITabBarController,
               let next = tabBar.selectedViewController
            {
                // 如果是标签栏控制器，获取选中的视图控制器并更新结果
                result = next
                continue
            }
            if let split = result as? UISplitViewController,
               let next = split.viewControllers.last
            {
                // 如果是分割视图控制器，获取最后一个视图控制器并更新结果
                result = next
                continue
            }
            if let navigator = result as? UINavigationController,
               let next = navigator.viewControllers.last
            {
                // 如果是导航控制器，获取栈顶的视图控制器并更新结果
                result = next
                continue
            }
            break
        }
        return result
    }
}

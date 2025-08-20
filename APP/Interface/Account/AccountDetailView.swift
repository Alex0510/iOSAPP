import ApplePackage
import SwiftUI

// 账户详情视图，显示账户的详细信息
struct AccountDetailView: View {
    // 要显示详情的账户对象
    let account: AppStore.Account

    // 应用状态管理对象
    @StateObject var vm = AppStore.this
    // 用于关闭当前视图的环境变量
    @Environment(\.dismiss) var dismiss

    // 令牌旋转状态标志
    @State var rotating = false
    // 令牌旋转提示信息
    @State var rotatingHint = ""

    var body: some View {
        // 使用 List 组件展示账户详情
        List {
            // 显示账户 ID 部分
            Section {
                // 演示模式下显示占位文本
                if vm.demoMode {
                    Text("88888888888")
                        .redacted(reason: .placeholder)
                } else {
                    // 非演示模式下显示账户邮箱，并支持点击复制
                    Text(account.email)
                        .onTapGesture { UIPasteboard.general.string = account.email }
                }
            } header: {
                // 该部分的标题
                Text("ID")
            } footer: {
                // 该部分的底部说明文本
                Text("This email is used to sign in to Apple services.")
            }
            // 显示国家代码部分
            Section {
                // 显示国家代码及其对应的国家名称，支持点击复制邮箱
                Text("\(account.countryCode) - \(ApplePackage.countryCodeMap[account.countryCode] ?? NSLocalizedString("Unknown", comment: ""))")
                    .onTapGesture { UIPasteboard.general.string = account.email }
            } header: {
                // 该部分的标题
                Text("Country Code")
            } footer: {
                // 该部分的底部说明文本
                Text("App Store requires this country code to identify your package region.")
            }
            // 显示服务 ID 部分
            Section {
                // 演示模式下显示占位文本
                if vm.demoMode {
                    Text("88888888888")
                        .redacted(reason: .placeholder)
                } else {
                    // 非演示模式下显示目录服务标识符，并支持点击复制邮箱
                    Text(account.storeResponse.directoryServicesIdentifier)
                        .font(.system(.body, design: .monospaced))
                        .onTapGesture { UIPasteboard.general.string = account.email }
                }
                // 显示覆盖的 GUID 或提示信息，并支持点击复制邮箱
                Text(ApplePackage.overrideGUID ?? "Seed Not Available")
                    .font(.system(.body, design: .monospaced))
                    .onTapGesture { UIPasteboard.general.string = account.email }
            } header: {
                // 该部分的标题
                Text("Services ID")
            } footer: {
                // 该部分的底部说明文本
                Text("ID combined with a random seed generated on this device can download package from App Store.")
            }
            // 显示密码令牌部分
            Section {
                // 显示密码令牌的安全输入框
                SecureField(text: .constant(account.storeResponse.passwordToken)) {
                    Text("Password Token")
                }
                // 根据令牌旋转状态显示不同按钮
                if rotating {
                    // 旋转中，显示禁用状态的按钮
                    Button("Rotating...") {}
                        .disabled(true)
                } else {
                    // 未旋转，显示可点击的旋转按钮
                    Button("Rotate Token") { rotate() }
                }
            } header: {
                // 该部分的标题
                Text("Password Token")
            } footer: {
                // 根据旋转提示信息显示不同内容
                if rotatingHint.isEmpty {
                    // 无提示信息时显示默认说明
                    Text("If you failed to acquire license for product, rotate the password token may help. This will use the initial password to authenticate with App Store again.")
                } else {
                    // 有提示信息时显示提示内容，颜色为红色
                    Text(rotatingHint)
                        .foregroundStyle(.red)
                }
            }
            // 显示删除按钮部分
            Section {
                // 删除账户的按钮，点击后删除账户并关闭当前视图
                Button("Delete") {
                    vm.delete(id: account.id)
                    dismiss()
                }
                .foregroundStyle(.red)
            }
        }
        // 设置导航栏标题
        .navigationTitle("Detail")
    }

    // 旋转密码令牌的方法
    func rotate() {
        // 标记为旋转中
        rotating = true
        // 在全局队列异步执行旋转操作
        DispatchQueue.global().async {
            do {
                // 尝试执行旋转操作
                try vm.rotate(id: account.id)
                // 在主线程更新 UI，标记旋转结束并显示成功提示
                DispatchQueue.main.async {
                    rotating = false
                    rotatingHint = NSLocalizedString("Success", comment: "")
                }
            } catch {
                // 在主线程更新 UI，标记旋转结束并显示错误信息
                DispatchQueue.main.async {
                    rotating = false
                    rotatingHint = error.localizedDescription
                }
            }
        }
    }
}
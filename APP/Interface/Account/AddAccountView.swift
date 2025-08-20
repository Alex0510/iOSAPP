// 导入 Apple 相关功能包
import ApplePackage
// 导入 SwiftUI 框架
import SwiftUI

// 定义一个名为 AddAccountView 的视图结构体
struct AddAccountView: View {
    // 获取 AppStore 的单例实例
    @StateObject var vm = AppStore.this
    // 获取视图关闭的环境值
    @Environment(\.dismiss) var dismiss

    // 用于存储输入的邮箱地址
    @State var email: String = ""
    // 用于存储输入的密码
    @State var password: String = ""

    // 标记是否需要输入 2FA 验证码
    @State var codeRequired: Bool = false
    // 用于存储输入的 2FA 验证码
    @State var code: String = ""

    // 用于存储可能出现的错误
    @State var error: Error?
    // 标记是否显示进度视图
    @State var openProgress: Bool = false

    // 视图的主体内容
    var body: some View {
        // 创建一个列表视图
        List {
            // 创建一个列表分区
            Section {
                // 邮箱输入框，禁用自动修正和自动大写
                TextField("Email (Apple ID)", text: $email)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                // 密码输入框，安全显示输入内容
                SecureField("Password", text: $password)
            } header: {
                // 分区的标题
                Text("ID")
            } footer: {
                // 分区的底部说明文字
                Text("We will store your account and password on disk without encryption. Please do not connect your device to untrusted hardware or use this app on a open system like macOS.")
            }
            // 如果需要输入 2FA 验证码，则显示对应的输入分区
            if codeRequired {
                Section {
                    // 2FA 验证码输入框，禁用自动修正和自动大写，使用数字键盘
                    TextField("2FA Code (Optional)", text: $code)
                        .disableAutocorrection(true)
                        .autocapitalization(.none)
                        .keyboardType(.numberPad)
                } header: {
                    // 分区的标题
                    Text("2FA Code")
                } footer: {
                    // 分区的底部说明文字
                    Text("Although 2FA code is marked as optional, that is because we dont know if you have it or just incorrect password, you should provide it if you have it enabled.\n\nhttps://support.apple.com/102606")
                }
                // 添加透明度过渡动画
                .transition(.opacity)
            }
            // 创建一个新的列表分区
            Section {
                // 如果正在验证，则显示进度视图
                if openProgress {
                    ForEach([UUID()], id: \.self) { _ in
                        ProgressView()
                    }
                } else {
                    // 认证按钮，点击后调用 authenticate 方法
                    Button("Authenticate") {
                        authenticate()
                    }
                    // 在验证过程中禁用按钮
                    .disabled(openProgress)
                    // 邮箱或密码为空时禁用按钮
                    .disabled(email.isEmpty || password.isEmpty)
                }
            } footer: {
                // 如果有错误发生，则显示错误信息
                if let error {
                    Text(error.localizedDescription)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                        // 添加透明度过渡动画
                        .transition(.opacity)
                }
            }
        }
        // 当 codeRequired 值变化时添加弹簧动画
        .animation(.spring, value: codeRequired)
        // 设置列表样式为内嵌分组样式
        .listStyle(.insetGrouped)
        // 设置导航栏标题
        .navigationTitle("Add Account")
    }

    // 认证方法
    func authenticate() {
        // 开始验证，显示进度视图
        openProgress = true
        // 在全局队列中异步执行认证操作
        DispatchQueue.global().async {
            // 无论认证成功或失败，最后都要隐藏进度视图
            defer { DispatchQueue.main.async { openProgress = false } }
            // 创建认证器实例
            let auth = ApplePackage.Authenticator(email: email)
            do {
                // 执行认证操作
                let account = try auth.authenticate(password: password, code: code.isEmpty ? nil : code)
                // 在主线程中保存账号信息并关闭当前视图
                DispatchQueue.main.async {
                    vm.save(email: email, password: password, account: account)
                    dismiss()
                }
            } catch {
                // 在主线程中处理认证错误，显示错误信息并标记需要 2FA 验证码
                DispatchQueue.main.async {
                    self.error = error
                    codeRequired = true
                }
            }
        }
    }
}

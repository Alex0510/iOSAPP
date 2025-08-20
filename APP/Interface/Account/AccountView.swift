import ApplePackage
import Combine
import SwiftUI

// 账户视图，显示账户列表和添加账户的功能
struct AccountView: View {
    // 应用状态管理对象
    @StateObject var vm = AppStore.this
    // 控制是否显示添加账户视图的状态
    @State var addAccount = false

    // 视图主体内容
    var body: some View {
        // 导航视图容器
        NavigationView {
            // 显示账户列表内容
            content
                // 在背景中添加导航链接，用于控制添加账户视图的显示
                .background(
                    NavigationLink(
                        destination: AddAccountView(), // 导航目标为添加账户视图
                        isActive: $addAccount, // 通过状态变量控制是否激活导航
                        label: { EmptyView() } // 使用空视图作为标签
                    )
                )
                // 设置导航栏标题
                .navigationTitle("Account")
                // 配置工具栏
                .toolbar {
                    // 工具栏项
                    ToolbarItem {
                        // 按钮，用于触发添加账户操作
                        Button {
                            // 切换添加账户视图的显示状态
                            addAccount.toggle()
                        } label: {
                            // 按钮标签，显示文本和加号图标
                            Label("Add Account", systemImage: "plus")
                        }
                    }
                }
        }
        // 设置导航视图样式为堆叠样式
        .navigationViewStyle(.stack)
    }

    // 账户列表内容视图
    var content: some View {
        // 列表视图
        List {
            // 列表分区
            Section {
                // 遍历应用状态中的账户列表
                ForEach(vm.accounts) { account in
                    // 导航链接，点击后跳转到账户详情视图
                    NavigationLink(destination: AccountDetailView(account: account)) {
                        if vm.demoMode {
                            // 演示模式下显示占位文本
                            Text("88888888888")
                                .redacted(reason: .placeholder)
                        } else {
                            // 非演示模式下显示账户邮箱
                            Text(account.email)
                        }
                    }
                }
                // 如果账户列表为空，显示提示文本
                if vm.accounts.isEmpty {
                    Text("Sorry, nothing here.")
                }
            } header: {
                // 分区头部文本
                Text("IDs")
            } footer: {
                // 分区底部文本，提示账户未在磁盘加密
                Text("Your account is not encrypted on disk.")
            }
        }
    }
}

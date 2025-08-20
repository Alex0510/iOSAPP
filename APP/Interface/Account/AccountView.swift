import ApplePackage
import Combine
import SwiftUI

// 账户视图，显示账户列表和添加账户的功能
struct AccountView: View {
    // 应用状态管理对象
    @StateObject var vm = AppStore.this
    // 控制是否显示添加账户视图的状态
    @State var addAccount = false

    var body: some View {
        NavigationView {
            content
                .background(
                    NavigationLink(
                        destination: AddAccountView(),
                        isActive: $addAccount,
                        label: { EmptyView() }
                    )
                )
                .navigationTitle("Account")
                .toolbar {
                    ToolbarItem {
                        Button {
                            addAccount.toggle()
                        } label: {
                            Label("Add Account", systemImage: "plus")
                        }
                    }
                }
        }
        .navigationViewStyle(.stack)
    }

    // 账户列表内容视图
    var content: some View {
        List {
            Section {
                ForEach(vm.accounts) { account in
                    NavigationLink(destination: AccountDetailView(account: account)) {
                        if vm.demoMode {
                            Text("88888888888")
                                .redacted(reason: .placeholder)
                        } else {
                            Text(account.email)
                        }
                    }
                }
                if vm.accounts.isEmpty {
                    Text("Sorry, nothing here.")
                }
            } header: {
                Text("IDs")
            } footer: {
                Text("Your account is not encrypted on disk.")
            }
        }
    }
}

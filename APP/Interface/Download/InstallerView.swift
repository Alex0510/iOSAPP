import SwiftUI

// 定义安装器视图结构体
struct InstallerView: View {
    // 使用 @StateObject 管理安装器实例
    @StateObject var installer: Installer

    // 根据安装器状态获取对应的图标名称
    var icon: String {
        switch installer.status {
        case .ready:
            "app.gift"
        case .sendingManifest:
            "paperplane.fill"
        case .sendingPayload:
            "paperplane.fill"
        case let .completed(result):
            switch result {
            case .success:
                "app.badge.checkmark"
            case .failure:
                "exclamationmark.triangle.fill"
            }
        case .broken:
            "exclamationmark.triangle.fill"
        }
    }

    // 根据安装器状态获取对应的文本描述
    var text: String {
        switch installer.status {
        case .ready: NSLocalizedString("Ready To Install", comment: "")
        case .sendingManifest: NSLocalizedString("Sending Manifest...", comment: "")
        case .sendingPayload: NSLocalizedString("Sending Payload...", comment: "")
        case let .completed(result):
            switch result {
            case .success:
                NSLocalizedString("Install Completed", comment: "")
            case let .failure(failure):
                failure.localizedDescription
            }
        case let .broken(error):
            error.localizedDescription
        }
    }

    // 视图主体内容
    var body: some View {
        // 使用 ZStack 进行视图层叠
        ZStack {
            // 垂直排列视图，间距为 32
            VStack(spacing: 32) {
                // 遍历图标数组并显示图标
                ForEach([icon], id: \.self) { icon in
                    Image(systemName: icon)
                        .font(.system(.largeTitle, design: .rounded))
                        .transition(.opacity.combined(with: .scale))
                }
                // 遍历文本数组并显示文本
                ForEach([text], id: \.self) { text in
                    Text(text)
                        .font(.system(.body, design: .rounded))
                        .transition(.opacity)
                }
            }
            .contentShape(Rectangle())
            // 添加点击手势，当状态为 ready 时打开 iTunes 链接
            .onTapGesture {
                if case .ready = installer.status {
                    UIApplication.shared.open(installer.iTunesLink)
                }
            }
            // 视图出现时，若状态为 ready 则打开 iTunes 链接
            .onAppear {
                if case .ready = installer.status {
                    UIApplication.shared.open(installer.iTunesLink)
                }
            }
            // 底部显示提示信息的垂直排列视图
            VStack {
                Text("To install app, you need to grant local area network permission in order to communicate with system services.")
            }
            .font(.system(.footnote, design: .rounded))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .padding(32)
        }
        // 当文本变化时添加弹簧动画
        .animation(.spring, value: text)
        // 当图标变化时添加弹簧动画
        .animation(.spring, value: icon)
        // 视图消失时调用安装器的销毁方法
        .onDisappear {
            installer.destroy()
        }
    }
}

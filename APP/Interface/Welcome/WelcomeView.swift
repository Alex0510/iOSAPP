// 导入必要的框架
import ColorfulX  // 彩色视图库
import SwiftUI    // UI框架

/// 欢迎界面视图
struct WelcomeView: View {
    /// 应用版本号
    private var appVersion: String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return "Version: \(version)"
        }
        return "Version: Unknown"
    }
    /// 视图内容
    var body: some View {
        // 叠加视图容器
        ZStack {
            // 主内容垂直堆栈
            VStack(spacing: 32) {
                // 应用图标
                Image(.avatar)
                    .resizable()  // 可调整大小
                    .aspectRatio(contentMode: .fit)  // 保持宽高比
                    .frame(width: 80, height: 80)  // 设置尺寸
                // 欢迎文本
                Text("Welcome to Asspp")
                    .font(.system(.headline, design: .rounded))  // 标题字体
                // 安装步骤说明
                inst
                    .font(.system(.footnote, design: .rounded))  // 脚注字体
                    .padding(.horizontal, 32)  // 水平方向内边距
                // 间隔器，高度为0
                Spacer().frame(height: 0)
            }

        // 底部信息垂直堆栈 - 包含版本信息和提示文本
        VStack(spacing: 16) {
                Spacer()
                // 应用版本信息
                Text(appVersion)  // 显示应用的版本号
                // 提示文本
                Text("App Store本身不稳定，必要时请重试。")
            }
            .font(.footnote)  // 脚注字体
            .foregroundStyle(.secondary)  // 次要文本颜色
            .padding()  // 添加内边距
        }
        // 设置视图大小为全屏
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // 背景视图
        .background(
            // 彩色背景视图
            ColorfulView(color: .constant(ColorfulPreset.winter.colors))
                .opacity(0.25)  // 透明度25%
                .ignoresSafeArea()  // 忽略安全区域
        )
    }

    /// 安装步骤说明视图
    var inst: some View {
        VStack(spacing: 16) {
            // 水平堆栈
            HStack {
                // 步骤1图标
                Image(systemName: "1.circle.fill")
                // 步骤1文本
                Text("登录您的账户。")
            }
            .frame(maxWidth: .infinity, alignment: .leading)  // 宽度最大化，左对齐

            // 水平堆栈
            HStack {
                // 步骤2图标
                Image(systemName: "2.circle.fill")
                // 步骤2文本
                Text("搜索您想要安装的应用。")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 水平堆栈
            HStack {
                // 步骤3图标
                Image(systemName: "3.circle.fill")
                // 步骤3文本
                Text("下载并保存ipa文件。")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 水平堆栈
            HStack {
                // 步骤4图标
                Image(systemName: "4.circle.fill")
                // 步骤4文本
                Text("安装或通过AirDrop安装。")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

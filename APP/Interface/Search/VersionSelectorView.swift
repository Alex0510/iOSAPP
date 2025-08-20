import SwiftUI
import Kingfisher

// 应用信息结构体
struct AppInfo {
    let name: String
    let developer: String
    let iconURL: String
    let identifier: String
}

// 版本选择器视图
struct VersionSelectorView: View {
    // 应用信息
    let appInfo: AppInfo
    // 版本列表
    let versions: [String]
    // 版本选择回调
    let onVersionSelected: (String) -> Void
    // 取消回调
    let onCancel: () -> Void
    // 选中的版本索引
    @State private var selectedVersionIndex: Int = 0
    // 加载状态
    @State private var isLoading: Bool = false
    // 错误信息
    @State private var errorMessage: String?

    var body: some View {
        VStack {
            // 标题栏
            HStack {
                Text("选择版本")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("取消") {
                    onCancel()
                }
                .foregroundColor(.blue)
            }
            .padding()

            // 应用信息卡片
            HStack {
                // 应用图标
                KFImage(URL(string: appInfo.iconURL))
                    .resizable()
                    .frame(width: 60, height: 60)
                    .cornerRadius(12)

                // 应用信息
                VStack(alignment: .leading) {
                    Text(appInfo.name)
                        .font(.headline)
                    Text(appInfo.developer)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Text("ID: \(appInfo.identifier)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding(.leading)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding()

            // 版本列表
            if versions.isEmpty {
                Text("未找到版本信息")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                List(0..<versions.count, id: \.self) {
                    index in
                    Button(action: {
                        selectedVersionIndex = index
                    }) {
                        HStack {
                            Text("版本 \(versions[index])")
                            Spacer()
                            if selectedVersionIndex == index {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .listRowBackground(selectedVersionIndex == index ? Color(.systemGray5) : Color.clear)
                }
                .listStyle(PlainListStyle())
                .frame(height: 200)
            }

            // 错误信息
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }

            // 下载按钮
            Button(action: {
                downloadSelectedVersion()
            }) {
                if isLoading {
                    ProgressView()
                        .frame(width: 20, height: 20)
                } else {
                    Text("下载所选版本")
                }
            }
            .disabled(isLoading || versions.isEmpty)
            .padding()
            .background(isLoading || versions.isEmpty ? Color.gray : Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding()
        }
        .background(Color.white)
        .cornerRadius(20)
        .padding()
        .frame(maxWidth: 500)
        .centered()
    }

    // 下载选中的版本
    private func downloadSelectedVersion() {
        isLoading = true
        errorMessage = nil

        // 模拟下载延迟
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let selectedVersion = versions[selectedVersionIndex]
            onVersionSelected(selectedVersion)
            isLoading = false
        }
    }
}

// 扩展View，添加居中显示功能
extension View {
    func centered() -> some View {
        self
            .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
    }
}
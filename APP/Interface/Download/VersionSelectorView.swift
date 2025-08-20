// 导入 SwiftUI 框架
import SwiftUI

// 定义版本选择视图结构体
struct VersionSelectorView: View {
    // 应用信息
    let appInfo: AppInfo
    // 版本列表
    let versions: [String]
    // 版本选择回调闭包
    let onVersionSelected: (String) -> Void
    // 取消操作回调闭包
    let onCancel: () -> Void
    
    // 记录当前选中的版本
    @State private var selectedVersion: String = ""
    
    // 视图主体
    var body: some View {
        // 垂直排列视图，间距为 20
        VStack(spacing: 20) {
            // 水平排列视图
            HStack {
                // 异步加载图片
                AsyncImage(url: URL(string: appInfo.iconURL)) { image in
                    // 图片可调整大小，并保持宽高比填充
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    // 图片加载占位图，圆角矩形，灰色半透明填充
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.gray.opacity(0.3))
                }
                // 设置图片大小
                .frame(width: 60, height: 60)
                // 裁剪为圆角矩形
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // 垂直排列视图，左对齐
                VStack(alignment: .leading) {
                    // 显示应用名称，使用标题字体，最多显示两行
                    Text(appInfo.name)
                        .font(.headline)
                        .lineLimit(2)
                    
                    // 显示应用开发者，使用子标题字体，次要颜色
                    Text(appInfo.developer)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // 添加间隔，将前面的视图推到左侧
                Spacer()
            }
            
            // 垂直排列视图，左对齐，间距为 12
            VStack(alignment: .leading, spacing: 12) {
                // 显示选择版本的提示文字
                Text("选择要下载的版本:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                // 可滚动视图
                ScrollView {
                    // 惰性垂直排列视图，间距为 8
                    LazyVStack(spacing: 8) {
                        // 遍历版本列表
                        ForEach(versions, id: \.self) { version in
                            // 水平排列视图
                            HStack {
                                // 版本选择按钮
                                Button(action: {
                                    // 点击按钮时更新选中的版本
                                    selectedVersion = version
                                }) {
                                    // 水平排列按钮内容
                                    HStack {
                                        // 根据是否选中显示不同的图标
                                        Image(systemName: selectedVersion == version ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedVersion == version ? .blue : .gray)
                                        
                                        // 显示版本号
                                        Text("版本 \(version)")
                                            .font(.system(.body, design: .monospaced))
                                        
                                        // 添加间隔，将前面的内容推到左侧
                                        Spacer()
                                        
                                        // 如果是第一个版本，显示“最新版本”标签
                                        if version == versions.first {
                                            Text("最新版本")
                                                .font(.caption)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 2)
                                                .background(.blue.opacity(0.1))
                                                .foregroundColor(.blue)
                                                .clipShape(Capsule())
                                        }
                                    }
                                    // 设置按钮内边距
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    // 根据是否选中设置不同的背景颜色
                                    .background(selectedVersion == version ? .blue.opacity(0.1) : .gray.opacity(0.05))
                                    // 裁剪为圆角矩形
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                // 设置按钮样式为普通样式
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                // 设置滚动视图最大高度为 200
                .frame(maxHeight: 200)
            }
            
            // 水平排列按钮，间距为 12
            HStack(spacing: 12) {
                // 取消按钮
                Button("取消") {
                    // 点击取消按钮时调用取消回调
                    onCancel()
                }
                // 设置按钮样式为带边框样式
                .buttonStyle(.bordered)
                
                // 下载选中版本按钮
                Button("下载选中版本") {
                    // 如果已选中版本，则调用版本选择回调
                    if !selectedVersion.isEmpty {
                        onVersionSelected(selectedVersion)
                    }
                }
                // 设置按钮样式为突出的带边框样式
                .buttonStyle(.borderedProminent)
                // 如果未选中版本，禁用按钮
                .disabled(selectedVersion.isEmpty)
            }
        }
        // 设置视图内边距为 24
        .padding(24)
        // 设置视图宽度为 400
        .frame(width: 400)
        // 设置视图背景为常规材质
        .background(.regularMaterial)
        // 裁剪为圆角矩形
        .clipShape(RoundedRectangle(cornerRadius: 16))
        // 添加阴影效果
        .shadow(radius: 20)
        // 视图出现时，默认选中第一个版本
        .onAppear {
            selectedVersion = versions.first ?? ""
        }
    }
}

// 定义应用信息结构体
struct AppInfo {
    // 应用名称
    let name: String
    // 应用开发者
    let developer: String
    // 应用图标 URL
    let iconURL: String
}
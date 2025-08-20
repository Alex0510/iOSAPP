// 导入 SwiftUI 框架
import SwiftUI

// 定义下载视图结构体
struct DownloadView: View {
    // 使用 @StateObject 修饰下载视图模型，确保在视图生命周期内保持单例
    @StateObject var vm = Downloads.this

    // 视图主体内容
    var body: some View {
        // 创建导航视图
        NavigationView {
            // 显示内容视图
            content
                // 设置导航栏标题为 "Download"
                .navigationTitle("Download")
        }
        // 设置导航视图样式为堆栈样式
        .navigationViewStyle(.stack)
    }

    // 定义内容视图
    var content: some View {
        // 创建列表视图
        List {
            // 如果下载请求列表为空
            if vm.requests.isEmpty {
                // 创建一个名为 "Packages" 的列表分区
                Section("Packages") {
                    // 显示提示信息，表示没有内容
                    Text("Sorry, nothing here.")
                }
            } else {
                // 创建一个名为 "Packages" 的列表分区
                Section("Packages") {
                    // 显示下载包列表
                    packageList
                }
            }
        }
        // 设置工具栏
        .toolbar {
            // 创建导航链接，点击后跳转到添加下载视图
            NavigationLink(destination: AddDownloadView()) {
                // 显示加号图标
                Image(systemName: "plus")
            }
        }
    }

    // 定义下载包列表视图
    var packageList: some View {
        // 遍历下载请求列表
        ForEach(vm.requests) { req in
            // 创建导航链接，点击后跳转到包详情视图
            NavigationLink(destination: PackageView(request: req)) {
                // 创建垂直堆栈视图
                VStack(spacing: 8) {
                    // 显示归档文件预览视图
                    ArchivePreviewView(archive: req.package)
                    // 显示进度条视图，并添加动画效果
                    SimpleProgress(progress: req.runtime.progress)
                        .animation(.interactiveSpring, value: req.runtime.progress)
                    // 创建水平堆栈视图
                    HStack {
                        // 显示下载请求的提示信息
                        Text(req.hint)
                        // 添加间隔，使内容靠右对齐
                        Spacer()
                        // 显示下载请求的创建时间
                        Text(req.creation.formatted())
                    }
                    // 设置字体样式为小注脚，设计风格为圆角
                    .font(.system(.footnote, design: .rounded))
                    // 设置文字颜色为次要颜色
                    .foregroundStyle(.secondary)
                }
            }
            // 添加从左侧滑出的操作按钮
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                // 如果下载请求已完成，则不做任何操作
                if vm.isCompleted(for: req) {
                } else {
                    // 根据下载请求的运行状态进行判断
                    switch req.runtime.status {
                    case .stopped:
                        // 创建恢复按钮，点击后恢复下载
                        Button {
                            vm.resume(requestID: req.id)
                        } label: {
                            Label("Resume", systemImage: "play.fill")
                        }
                    case .pending, .downloading:
                        // 原代码存在拼写错误，"Puase" 应改为 "Pause"
                        // 创建暂停按钮，点击后暂停下载
                        Button {
                            vm.suspend(requestID: req.id)
                        } label: {
                            Label("Pause", systemImage: "stop.fill")
                        }
                    default: 
                        // 默认情况不做任何操作
                        Group {}
                    }
                }
            }
            // 添加从右侧滑出的操作按钮
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                // 创建删除按钮，点击后删除下载请求
                Button(role: .destructive) {
                    vm.delete(request: req)
                } label: {
                    Label("Cancel", systemImage: "trash")
                }
            }
        }
    }
}

// 为 Downloads.Request 添加扩展
extension Downloads.Request {
    // 定义计算属性 hint，用于获取下载请求的提示信息
    var hint: String {
        // 如果存在运行时错误，则返回错误信息
        if let error = runtime.error {
            return error
        }
        // 根据下载请求的运行状态返回不同的提示信息
        return switch runtime.status {
        case .stopped:
            NSLocalizedString("Suspended", comment: "")
        case .pending:
            NSLocalizedString("Pending...", comment: "")
        case .downloading:
            [
                String(Int(runtime.progress.fractionCompleted * 100)) + "%",
                runtime.speed.isEmpty ? "" : runtime.speed + "/s",
            ]
            .compactMap { $0 }
            .joined(separator: " ")
        case .verifying:
            NSLocalizedString("Verifying...", comment: "")
        case .completed:
            NSLocalizedString("Completed", comment: "")
        }
    }
}

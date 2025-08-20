// 导入必要的框架
import ApplePackage  // Apple包管理相关功能
import Logging       // 日志记录
import UIKit         // UI组件
import Vapor         // Web服务器框架

/// 安装器类：负责处理应用的安装过程
class Installer: Identifiable, ObservableObject {
    /// 唯一标识符
    let id: UUID
    /// Vapor应用实例
    let app: Application
    /// iTunes存档对象
    let archive: iTunesResponse.iTunesArchive
    /// 随机端口号(4000-8000)
    let port = Int.random(in: 4000 ... 8000)

    /// 安装器状态枚举
    enum Status {
        case ready              // 准备就绪
        case sendingManifest    // 正在发送清单
        case sendingPayload     // 正在发送 payload
        case completed(Result<Void, Error>)  // 完成(成功或失败)
        case broken(Error)      // 出错
    }

    /// 安装器当前状态（发布属性，用于UI绑定）
    @Published var status: Status = .ready

    /// 是否需要关闭服务器
    var needsShutdown = false

    /// 初始化安装器
    /// - Parameters:
    ///   - archive: iTunes存档对象
    ///   - packagePath: 安装包路径
    init(archive: iTunesResponse.iTunesArchive, path packagePath: URL) throws {
        // 生成唯一标识符
        let id: UUID = .init()
        self.id = id
        self.archive = archive
        // 设置Vapor应用
        app = try Self.setupApp(port: port)

        // 设置路由处理器，处理所有GET请求
        app.get("*") { [weak self] req in
            // 确保self未被释放
            guard let self else { return Response(status: .badGateway) }

            // 根据URL路径处理不同请求
            switch req.url.path {
            // 健康检查端点
            case "/ping":
                // 返回健康检查响应
                return Response(status: .ok, body: .init(string: "pong"))
            // 首页端点
            case "/", "/index.html":
                // 返回HTML页面
                return Response(status: .ok, version: req.version, headers: [
                    "Content-Type": "text/html",
                ], body: .init(string: indexHtml))
            // 安装清单端点
            case plistEndpoint.path:
                // 更新状态为正在发送清单
                DispatchQueue.main.async { self.status = .sendingManifest }
                // 返回XML格式的安装清单
                return Response(status: .ok, version: req.version, headers: [
                    "Content-Type": "text/xml",
                ], body: .init(data: installManifestData))
            // 小图标端点
            case displayImageSmallEndpoint.path:
                DispatchQueue.main.async { self.status = .sendingManifest }
                // 返回小图标
                return Response(status: .ok, version: req.version, headers: [
                    "Content-Type": "image/png",
                ], body: .init(data: displayImageSmallData))
            // 大图标端点
            case displayImageLargeEndpoint.path:
                DispatchQueue.main.async { self.status = .sendingManifest }
                // 返回大图标
                return Response(status: .ok, version: req.version, headers: [
                    "Content-Type": "image/png",
                ], body: .init(data: displayImageLargeData))
            // 安装包端点
            case payloadEndpoint.path:
                // 更新状态为正在发送安装包
                DispatchQueue.main.async { self.status = .sendingPayload }
                // 流式传输安装包文件
                return req.fileio.streamFile(
                    at: packagePath.path
                ) { result in
                    // 传输完成后更新状态
                    DispatchQueue.main.async { self.status = .completed(result) }
                }
            // 未找到匹配的路径
            default:
                // 返回404未找到响应
                return Response(status: .notFound)
            }
        }

        // 启动服务器
        try app.server.start()
        // 标记需要关闭
        needsShutdown = true
        // 打印初始化信息
        print("[*] 安装器初始化在端口 \(port) 用于 sni \(Self.sni)")
    }

    /// 析构函数：在对象释放前调用
    deinit {
        // 销毁资源
        destroy()
    }

    /// 销毁安装器，释放资源
    func destroy() {
        // 打印销毁信息
        print("[*] 安装器销毁")
        // 如果需要关闭服务器
        if needsShutdown {
            // 重置关闭标志
            needsShutdown = false
            // 关闭服务器
            app.server.shutdown()
            // 关闭应用
            app.shutdown()
        }
    }
}

import Foundation
import Vapor

// 扩展 Installer 类
extension Installer {
    // 私有静态常量，用于检测环境并初始化日志系统
    private static let env: Environment = {
        // 尝试检测当前环境
        var env = try! Environment.detect()
        // 尝试根据环境初始化日志系统
        try! LoggingSystem.bootstrap(from: &env)
        return env
    }()

    // 静态方法，用于设置并返回一个 Application 实例
    static func setupApp(port: Int) throws -> Application {
        // 创建一个基于当前环境的 Application 实例
        let app = Application(env)

        // 设置线程池，线程数量为 1
        app.threadPool = .init(numberOfThreads: 1)

        // 设置 HTTP 服务器的 TLS 配置
        app.http.server.configuration.tlsConfiguration = try Self.setupTLS()
        // 设置 HTTP 服务器的主机名
        app.http.server.configuration.hostname = Self.sni
        // 启用 TCP 无延迟选项
        app.http.server.configuration.tcpNoDelay = true

        // 设置 HTTP 服务器的监听地址
        app.http.server.configuration.address = .hostname("0.0.0.0", port: port)
        // 设置 HTTP 服务器的监听端口
        app.http.server.configuration.port = port

        // 设置路由的最大请求体大小为 128MB
        app.routes.defaultMaxBodySize = "128mb"
        // 设置路由不区分大小写
        app.routes.caseInsensitive = false

        // 返回配置好的 Application 实例
        return app
    }
}

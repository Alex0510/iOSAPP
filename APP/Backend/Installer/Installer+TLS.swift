// 导入基础框架
import Foundation
// 导入 NIOSSL 框架，用于处理 SSL 相关操作
import NIOSSL
// 导入 NIOTLS 框架，用于处理 TLS 相关操作
import NIOTLS
// 导入 Vapor 框架
import Vapor

// 为 Installer 添加扩展
extension Installer {
    // 定义服务器名称指示（SNI），用于 TLS 握手
    static let sni = "app.localhost.direct"
    // 获取本地证书的私钥文件路径
    static let pem = Bundle.main.url(
        forResource: "localhost.direct",
        withExtension: "pem",
        subdirectory: "Certificates/localhost.direct"
    )
    // 获取本地证书文件路径
    static let crt = Bundle.main.url(
        forResource: "localhost.direct",
        withExtension: "crt",
        subdirectory: "Certificates/localhost.direct"
    )

    // 设置 TLS 配置的静态方法，可能会抛出错误
    static func setupTLS() throws -> TLSConfiguration {
        // 检查证书文件和私钥文件是否成功加载
        guard let crt, let pem else {
            // 若加载失败，抛出错误
            throw NSError(domain: "Installer", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "Failed to load ssl certificates",
            ])
        }
        // 创建并返回服务器的 TLS 配置
        return try TLSConfiguration.makeServerConfiguration(
            // 从证书文件加载证书链
            certificateChain: NIOSSLCertificate
                .fromPEMFile(crt.path)
                .map { NIOSSLCertificateSource.certificate($0) },
            // 从文件加载私钥
            privateKey: .file(pem.path)
        )
    }
}

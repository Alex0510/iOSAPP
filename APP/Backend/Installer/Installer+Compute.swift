import ApplePackage
import Foundation

// 为 Installer 类添加扩展，实现一些计算属性
extension Installer {
    // 获取 plist 文件的端点 URL
    var plistEndpoint: URL {
        var comps = URLComponents()
        comps.scheme = "https"  // 设置协议为 HTTPS
        comps.host = Self.sni   // 设置主机地址
        comps.path = "/\(id).plist"  // 设置路径
        comps.port = port       // 设置端口号
        return comps.url!       // 返回构建好的 URL
    }

    // 获取 payload 文件的端点 URL
    var payloadEndpoint: URL {
        var comps = URLComponents()
        comps.scheme = "https"  // 设置协议为 HTTPS
        comps.host = Self.sni   // 设置主机地址
        comps.path = "/\(id).ipa"  // 设置路径
        comps.port = port       // 设置端口号
        return comps.url!       // 返回构建好的 URL
    }

    // 获取 iTunes 服务链接
    var iTunesLink: URL {
        var comps = URLComponents()
        comps.scheme = "itms-services"  // 设置协议为 itms-services
        comps.path = "/"                // 设置路径
        comps.queryItems = [
            URLQueryItem(name: "action", value: "download-manifest"),  // 设置动作查询项
            URLQueryItem(name: "url", value: plistEndpoint.absoluteString),  // 设置 URL 查询项
        ]
        comps.port = port               // 设置端口号
        return comps.url!               // 返回构建好的 URL
    }

    // 获取小尺寸显示图片的端点 URL
    var displayImageSmallEndpoint: URL {
        var comps = URLComponents()
        comps.scheme = "https"  // 设置协议为 HTTPS
        comps.host = Self.sni   // 设置主机地址
        comps.path = "/app57x57.png"  // 设置路径
        comps.port = port       // 设置端口号
        return comps.url!       // 返回构建好的 URL
    }

    // 获取小尺寸显示图片的数据
    var displayImageSmallData: Data {
        createWhite(57)
    }

    // 获取大尺寸显示图片的端点 URL
    var displayImageLargeEndpoint: URL {
        var comps = URLComponents()
        comps.scheme = "https"  // 设置协议为 HTTPS
        comps.host = Self.sni   // 设置主机地址
        comps.path = "/app512x512.png"  // 设置路径
        comps.port = port       // 设置端口号
        return comps.url!       // 返回构建好的 URL
    }

    // 获取大尺寸显示图片的数据
    var displayImageLargeData: Data {
        createWhite(512)
    }

    // 获取重定向到 iTunes 链接的 HTML 内容
    var indexHtml: String {
        """
        <html> <head> <meta http-equiv="refresh" content="0;url=\(iTunesLink.absoluteString)"> </head> </html>
        """
    }

    // 获取安装清单数据
    var installManifest: [String: Any] {
        [
            "items": [
                [
                    "assets": [
                        [
                            "kind": "software-package",
                            "url": payloadEndpoint.absoluteString,
                        ],
                        [
                            "kind": "display-image",
                            "url": displayImageSmallEndpoint.absoluteString,
                        ],
                        [
                            "kind": "full-size-image",
                            "url": displayImageLargeEndpoint.absoluteString,
                        ],
                    ],
                    "metadata": [
                        "bundle-identifier": archive.bundleIdentifier,
                        "bundle-version": archive.version,
                        "kind": "software",
                        "title": archive.name,
                    ],
                ],
            ],
        ]
    }

    // 获取安装清单的二进制数据
    var installManifestData: Data {
        (try? PropertyListSerialization.data(
            fromPropertyList: installManifest,
            format: .xml,
            options: .zero
        )) ?? .init()
    }
}

// 导入 AnyCodable 库，用于处理任意可编码的数据
import AnyCodable
// 导入 ApplePackage 库
import ApplePackage
// 导入 Foundation 框架，提供基础的系统功能
import Foundation

// 定义一个私有常量 storeDir，用于存储包的目录
// 该目录是在文档目录下创建的 "Packages" 文件夹
private let storeDir = {
    let ret = documentsDirectory.appendingPathComponent("Packages")
    // 尝试创建目录，如果目录已存在则忽略错误
    try? FileManager.default.createDirectory(at: ret, withIntermediateDirectories: true)
    return ret
}()

// 为 Downloads 类型添加扩展
extension Downloads {
    // 定义一个请求结构体，实现 Identifiable、Codable 和 Hashable 协议
    struct Request: Identifiable, Codable, Hashable {
        // 唯一标识符，默认生成一个新的 UUID
        var id: UUID = .init()

        // 应用商店账户信息
        var account: AppStore.Account
        // iTunes 响应中的归档包信息
        var package: iTunesResponse.iTunesArchive

        // 下载的 URL
        var url: URL
        // 文件的 MD5 哈希值
        var md5: String
        // 存储响应中的签名信息数组
        var signatures: [StoreResponse.Item.Signature]
        // 元数据，使用 AnyCodable 存储任意可编码的数据
        var metadata: [String: AnyCodable]

        // 请求创建的日期
        var creation: Date
        // 目标存储位置，根据包信息和 MD5 值生成文件路径
        var targetLocation: URL {
            storeDir
                .appendingPathComponent(package.bundleIdentifier)
                .appendingPathComponent(package.version)
                .appendingPathComponent("\(md5)_\(id.uuidString)")
                .appendingPathExtension("ipa")
        }

        // 运行时信息，默认初始化
        var runtime: Runtime = .init()

        // 初始化方法，根据账户、包信息和存储响应项创建请求
        init(account: AppStore.Account, package: iTunesResponse.iTunesArchive, item: StoreResponse.Item) {
            self.account = account
            self.package = package
            url = item.url
            md5 = item.md5
            signatures = item.signatures
            creation = .init()
            // 尝试将 item 的元数据转换为 JSON 数据，再解码为 [String: AnyCodable] 类型
            if let jsonData = try? JSONSerialization.data(withJSONObject: item.metadata),
               let json = try? JSONDecoder().decode([String: AnyCodable].self, from: jsonData)
            {
                metadata = json
            } else {
                // 转换失败则将元数据初始化为空字典
                metadata = [:]
            }
        }
    }
}

// 为 Downloads.Request 结构体添加扩展
extension Downloads.Request {
    // 定义运行时结构体，实现 Codable 和 Hashable 协议
    struct Runtime: Codable, Hashable {
        // 定义下载状态枚举
        enum Status: String, Codable {
            case stopped  // 已停止
            case pending  // 待处理
            case downloading  // 下载中
            case verifying  // 验证中
            case completed  // 已完成
        }

        // 当前下载状态，默认值为已停止
        var status: Status = .stopped {
            // 状态改变时的回调，如果状态不是下载中，则清空速度信息
            didSet { if status != .downloading { speed = "" } }
        }

        // 下载速度，以字符串形式存储
        var speed: String = ""
        // 下载进度百分比
        var percent: Double = 0
        // 错误信息，可选字符串类型
        var error: String? = nil

        // 根据进度百分比生成 Progress 对象
        var progress: Progress {
            let p = Progress(totalUnitCount: 100)
            p.completedUnitCount = Int64(percent * 100)
            return p
        }
    }
}

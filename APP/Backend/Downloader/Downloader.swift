import Foundation
import ApplePackage
import AnyCodable

/// 下载器类，提供下载请求的统一接口
/// 作为Downloads类的包装器，简化下载操作
class Downloader: ObservableObject {
    /// 单例实例
    static let this = Downloader()
    
    /// Downloads实例
    private let downloads = Downloads.this
    
    /// 私有初始化方法，确保单例模式
    private init() {}
    
    /// 请求下载应用
    /// - Parameters:
    ///   - archive: iTunes应用归档信息
    ///   - account: 用户账户信息
    ///   - version: 可选的版本信息，用于下载特定版本
    /// - Returns: 下载请求对象
    /// - Throws: 下载过程中的错误
    @discardableResult
    func requestDownload(
        archive: iTunesResponse.iTunesArchive,
        account: AppStore.Account,
        version: String? = nil
    ) async throws -> Downloads.Request {
        
        // 使用ApplePackage.Downloader进行实际下载
        let appleDownloader = ApplePackage.Downloader()
        
        // 创建下载目录
        let downloadsDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        let appDirectory = downloadsDirectory.appendingPathComponent("APP123")
        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)
        
        // 生成文件名
        let fileName = "\(archive.name)_\(archive.version).ipa"
        let targetURL = appDirectory.appendingPathComponent(fileName)
        
        do {
            // 执行下载
            let downloadedURL = try await appleDownloader.download(
                entity: .app,
                bundleIdentifier: archive.bundleIdentifier,
                saveDirectory: appDirectory,
                fileName: fileName
            )
            
            // 创建下载请求对象
            let request = Downloads.Request(
                id: UUID(),
                version: version ?? archive.version,
                package: archive,
                account: account,
                url: downloadedURL,
                md5: "", // MD5将在下载完成后计算
                signatures: [],
                metadata: AnyCodable([
                    "bundleId": archive.bundleIdentifier,
                    "version": version ?? archive.version,
                    "name": archive.name,
                    "downloadDate": Date().timeIntervalSince1970
                ]),
                createdAt: Date(),
                targetLocation: targetURL
            )
            
            // 添加到下载管理器
            if let version = version {
                try downloads.add(request: request, version: version)
            } else {
                downloads.add(request: request)
            }
            
            return request
            
        } catch {
            throw DownloadError.downloadFailed(error.localizedDescription)
        }
    }
    
    /// 请求下载指定版本的应用
    /// - Parameters:
    ///   - archive: iTunes应用归档信息
    ///   - account: 用户账户信息
    ///   - appVersion: 应用版本信息
    /// - Returns: 下载请求对象
    /// - Throws: 下载过程中的错误
    @discardableResult
    func requestDownload(
        archive: iTunesResponse.iTunesArchive,
        account: AppStore.Account,
        appVersion: VersionModels.AppVersion
    ) async throws -> Downloads.Request {
        return try await requestDownload(
            archive: archive,
            account: account,
            version: appVersion.version
        )
    }
}

/// 下载错误枚举
enum DownloadError: LocalizedError {
    case downloadFailed(String)
    case invalidArchive
    case accountRequired
    
    var errorDescription: String? {
        switch self {
        case .downloadFailed(let message):
            return "下载失败: \(message)"
        case .invalidArchive:
            return "无效的应用归档"
        case .accountRequired:
            return "需要有效的账户信息"
        }
    }
}

/// 版本错误枚举
enum VersionError: LocalizedError {
    case versionSelectionRequired
    case versionNotFound
    case versionMismatch
    
    var errorDescription: String? {
        switch self {
        case .versionSelectionRequired:
            return "需要选择版本"
        case .versionNotFound:
            return "未找到指定版本"
        case .versionMismatch:
            return "版本不匹配"
        }
    }
}
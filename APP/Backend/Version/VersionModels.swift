import Foundation
import ApplePackage

/// 版本相关的数据模型
struct VersionModels {
    
    /// 应用版本信息
    struct AppVersion: Identifiable, Codable, Hashable {
        /// 版本唯一标识符
        let id: String
        /// 版本号字符串（如 "1.0.0"）
        let versionString: String
        /// 构建号
        let buildNumber: String?
        /// 发布日期
        let releaseDate: Date?
        /// 版本大小（字节）
        let fileSize: Int64?
        /// 是否为最新版本
        let isLatest: Bool
        /// 版本描述或更新说明
        let releaseNotes: String?
        /// 最低系统要求
        let minimumOSVersion: String?
        
        init(id: String, 
             versionString: String? = nil, 
             buildNumber: String? = nil,
             releaseDate: Date? = nil,
             fileSize: Int64? = nil,
             isLatest: Bool = false,
             releaseNotes: String? = nil,
             minimumOSVersion: String? = nil) {
            self.id = id
            self.versionString = versionString ?? id
            self.buildNumber = buildNumber
            self.releaseDate = releaseDate
            self.fileSize = fileSize
            self.isLatest = isLatest
            self.releaseNotes = releaseNotes
            self.minimumOSVersion = minimumOSVersion
        }
        
        /// 格式化的文件大小字符串
        var formattedFileSize: String {
            guard let fileSize = fileSize else { return "未知大小" }
            return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
        }
        
        /// 格式化的发布日期字符串
        var formattedReleaseDate: String {
            guard let releaseDate = releaseDate else { return "未知日期" }
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            formatter.locale = Locale(identifier: "zh_CN")
            return formatter.string(from: releaseDate)
        }
    }
    
    /// 版本获取请求
    struct VersionFetchRequest {
        /// 应用ID
        let appId: String
        /// 应用包标识符
        let bundleId: String?
        /// 地区代码
        let region: String
        /// 设备类型
        let deviceType: EntityType
        /// 是否强制刷新缓存
        let forceRefresh: Bool
        
        init(appId: String, 
             bundleId: String? = nil, 
             region: String = "US", 
             deviceType: EntityType = .iPhone, 
             forceRefresh: Bool = false) {
            self.appId = appId
            self.bundleId = bundleId
            self.region = region
            self.deviceType = deviceType
            self.forceRefresh = forceRefresh
        }
    }
    
    /// 版本获取响应
    struct VersionFetchResponse {
        /// 应用ID
        let appId: String
        /// 版本列表
        let versions: [AppVersion]
        /// 获取时间
        let fetchTime: Date
        /// 是否来自缓存
        let fromCache: Bool
        
        init(appId: String, versions: [AppVersion], fromCache: Bool = false) {
            self.appId = appId
            self.versions = versions
            self.fetchTime = Date()
            self.fromCache = fromCache
        }
    }
    
    /// 版本下载请求
    struct VersionDownloadRequest {
        /// 应用ID
        let appId: String
        /// 版本ID
        let versionId: String
        /// 应用信息
        let appInfo: iTunesResponse.iTunesArchive
        /// 账户信息
        let account: AppStore.Account
        /// 地区代码
        let region: String
        
        init(appId: String, 
             versionId: String, 
             appInfo: iTunesResponse.iTunesArchive, 
             account: AppStore.Account, 
             region: String) {
            self.appId = appId
            self.versionId = versionId
            self.appInfo = appInfo
            self.account = account
            self.region = region
        }
    }
}

/// 版本管理器的状态枚举
enum VersionManagerState {
    case idle
    case loading
    case loaded([VersionModels.AppVersion])
    case error(Error)
    
    /// 是否正在加载
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    /// 获取版本列表
    var versions: [VersionModels.AppVersion] {
        if case .loaded(let versions) = self {
            return versions
        }
        return []
    }
    
    /// 获取错误信息
    var error: Error? {
        if case .error(let error) = self {
            return error
        }
        return nil
    }
}

/// 版本相关的错误类型
enum VersionError: LocalizedError {
    case invalidAppId
    case noAccountSelected
    case authenticationRequired
    case networkUnavailable
    case serverError(String)
    case parseError(String)
    case noVersionsAvailable
    case downloadFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAppId:
            return "无效的应用ID"
        case .noAccountSelected:
            return "请选择一个账户"
        case .authenticationRequired:
            return "需要重新认证"
        case .networkUnavailable:
            return "网络不可用"
        case .serverError(let message):
            return "服务器错误: \(message)"
        case .parseError(let message):
            return "数据解析错误: \(message)"
        case .noVersionsAvailable:
            return "该应用没有可用的历史版本"
        case .downloadFailed(let message):
            return "下载失败: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .noAccountSelected:
            return "请在账户页面添加并选择一个有效的账户"
        case .authenticationRequired:
            return "请在账户页面重新登录"
        case .networkUnavailable:
            return "请检查网络连接后重试"
        case .serverError, .parseError, .downloadFailed:
            return "请稍后重试"
        case .noVersionsAvailable:
            return "该应用可能不支持历史版本下载"
        default:
            return "请检查输入信息并重试"
        }
    }
}
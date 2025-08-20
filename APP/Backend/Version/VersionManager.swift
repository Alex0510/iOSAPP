import Foundation
import ApplePackage
import Combine

/// 版本管理器类，负责获取和管理应用的历史版本信息
class VersionManager: ObservableObject {
    /// 单例实例
    static let shared = VersionManager()
    
    /// 当前版本管理状态
    @Published var state: VersionManagerState = .idle
    
    /// 缓存的版本信息，以应用ID为键
    private var versionCache: [String: [VersionModels.AppVersion]] = [:]
    
    /// 缓存过期时间（秒）
    private let cacheExpirationTime: TimeInterval = 300 // 5分钟
    
    /// 缓存时间戳
    private var cacheTimestamps: [String: Date] = [:]
    
    private init() {}
    
    /// 获取应用的历史版本列表
    /// - Parameters:
    ///   - request: 版本获取请求
    ///   - account: 用于认证的账户
    ///   - completion: 完成回调
    func fetchVersions(request: VersionModels.VersionFetchRequest, 
                      using account: AppStore.Account, 
                      completion: @escaping (Result<VersionModels.VersionFetchResponse, Error>) -> Void) {
        let appId = request.appId
        
        // 检查缓存是否有效
        if !request.forceRefresh, let cachedVersions = getCachedVersionsIfValid(for: appId) {
            let response = VersionModels.VersionFetchResponse(appId: appId, versions: cachedVersions, fromCache: true)
            DispatchQueue.main.async {
                self.state = .loaded(cachedVersions)
                completion(.success(response))
            }
            return
        }
        
        DispatchQueue.main.async {
            self.state = .loading
        }
        
        // 在后台队列执行网络请求
        DispatchQueue.global(qos: .userInitiated).async {
            self.performVersionFetch(request: request, account: account, completion: completion)
        }
    }
    
    /// 执行版本获取的具体实现
    private func performVersionFetch(request: VersionModels.VersionFetchRequest, 
                                   account: AppStore.Account, 
                                   completion: @escaping (Result<VersionModels.VersionFetchResponse, Error>) -> Void) {
        do {
            print("🔍 开始获取应用 \(request.appId) 的版本信息")
            
            // 创建HTTP客户端
            let httpClient = HTTPClient(urlSession: URLSession.shared)
            let storeClient = StoreClient(httpClient: httpClient)
            
            // 设置认证信息
            storeClient.directoryServicesIdentifier = account.storeResponse.directoryServicesIdentifier
            storeClient.passwordToken = account.storeResponse.passwordToken
            
            // 发送下载请求以获取版本信息（使用重下载标志获取历史版本）
            let downloadResponse = try storeClient.download(
                identifier: request.appId,
                directoryServicesIdentifier: account.storeResponse.directoryServicesIdentifier,
                passwordToken: account.storeResponse.passwordToken
            )
            
            // 解析版本信息
            let versions = self.parseVersionsFromResponse(downloadResponse, appId: request.appId)
            
            // 缓存结果
            self.cacheVersions(versions, for: request.appId)
            
            let response = VersionModels.VersionFetchResponse(appId: request.appId, versions: versions, fromCache: false)
            
            DispatchQueue.main.async {
                self.state = .loaded(versions)
                completion(.success(response))
            }
            
        } catch {
            print("❌ 获取版本信息失败: \(error)")
            let versionError = self.mapError(error)
            DispatchQueue.main.async {
                self.state = .error(versionError)
                completion(.failure(versionError))
            }
        }
    }
    
    /// 从下载响应中解析版本信息
    private func parseVersionsFromResponse(_ response: DownloadResponse, appId: String) -> [VersionModels.AppVersion] {
        print("📋 解析应用 \(appId) 的版本信息")
        
        guard let items = response.items, !items.isEmpty else {
            print("❌ 响应中没有找到应用项目")
            return []
        }
        
        let firstItem = items[0]
        
        // 获取版本标识符列表
        guard let versionIds = firstItem.softwareVersionExternalIdentifiers, !versionIds.isEmpty else {
            print("❌ 没有找到版本标识符")
            return []
        }
        
        print("✅ 找到 \(versionIds.count) 个版本: \(versionIds)")
        
        // 转换为AppVersion对象
        let versions = versionIds.enumerated().map { index, versionId in
            VersionModels.AppVersion(
                id: String(versionId),
                versionString: String(versionId),
                buildNumber: nil,
                releaseDate: nil,
                fileSize: firstItem.fileSizeBytes,
                isLatest: index == 0, // 第一个版本通常是最新版本
                releaseNotes: nil,
                minimumOSVersion: firstItem.minimumOSVersion
            )
        }
        
        return versions
    }
    
    /// 缓存版本信息
    private func cacheVersions(_ versions: [VersionModels.AppVersion], for appId: String) {
        versionCache[appId] = versions
        cacheTimestamps[appId] = Date()
    }
    
    /// 获取有效的缓存版本信息
    private func getCachedVersionsIfValid(for appId: String) -> [VersionModels.AppVersion]? {
        guard let cachedVersions = versionCache[appId],
              let timestamp = cacheTimestamps[appId],
              Date().timeIntervalSince(timestamp) < cacheExpirationTime else {
            return nil
        }
        return cachedVersions
    }
    
    /// 清除指定应用的版本缓存
    func clearCache(for appId: String) {
        versionCache.removeValue(forKey: appId)
        cacheTimestamps.removeValue(forKey: appId)
    }
    
    /// 清除所有版本缓存
    func clearAllCache() {
        versionCache.removeAll()
        cacheTimestamps.removeAll()
    }
    
    /// 获取缓存的版本信息
    func getCachedVersions(for appId: String) -> [VersionModels.AppVersion]? {
        return versionCache[appId]
    }
    
    /// 映射错误类型
    private func mapError(_ error: Error) -> VersionError {
        if let storeError = error as? StoreError {
            switch storeError {
            case .authenticationRequired:
                return .authenticationRequired
            case .networkError:
                return .networkUnavailable
            default:
                return .serverError(storeError.localizedDescription)
            }
        }
        return .serverError(error.localizedDescription)
    }
}

    /// 带重试机制的版本获取方法
    func fetchVersionsWithRetry(request: VersionModels.VersionFetchRequest,
                               using account: AppStore.Account,
                               maxRetries: Int = 3,
                               completion: @escaping (Result<VersionModels.VersionFetchResponse, Error>) -> Void) {
        
        func attemptFetch(attempt: Int) {
            fetchVersions(request: request, using: account) { result in
                switch result {
                case .success(let response):
                    completion(.success(response))
                case .failure(let error):
                    if attempt < maxRetries {
                        print("🔄 第 \(attempt) 次尝试失败，将在2秒后重试...")
                        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
                            attemptFetch(attempt: attempt + 1)
                        }
                    } else {
                        print("❌ 所有 \(maxRetries) 次尝试均失败")
                        completion(.failure(error))
                    }
                }
            }
        }
        
        attemptFetch(attempt: 1)
    }
}
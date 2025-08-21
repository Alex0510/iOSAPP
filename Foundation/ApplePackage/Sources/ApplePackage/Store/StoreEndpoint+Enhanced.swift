//
//  StoreEndpoint+Enhanced.swift
//  of pxx917144686
//
//  增强的Store端点枚举，支持更多配置选项
//  新增了购买、下载和搜索功能
//  每个功能都可以配置区域、GUID和其他参数
//  支持Legacy和新的认证方式
//  新增了查找和搜索功能
//

import Foundation

/// 增强的Store端点枚举，支持更多配置选项
enum EnhancedStoreEndpoint {
    case authenticate(prefix: String?, guid: String, useLegacy: Bool = false)
    case download(guid: String, region: String? = nil)
    case buy(region: String? = nil)
    case lookup(bundleId: String, country: String = "US")
    case search(term: String, country: String = "US", limit: Int = 50)
}

extension EnhancedStoreEndpoint: HTTPEndpoint {
    var url: URL {
        var components = URLComponents(string: path)!
        components.scheme = "https"
        components.host = host
        
        // 添加查询参数
        if let queryItems = self.queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        
        return components.url!
    }

    private var host: String {
        switch self {
        case let .authenticate(prefix, _, useLegacy):
            if useLegacy, let prefix = prefix, !prefix.isEmpty {
                return "\(prefix)-buy.itunes.apple.com"
            } else {
                return "auth.itunes.apple.com"
            }
        case let .buy(region):
            if let region = region {
                return "\(region)-buy.itunes.apple.com"
            }
            return "buy.itunes.apple.com"
        case let .download(_, region):
            if let region = region {
                return "\(region)-buy.itunes.apple.com"
            }
            return "p25-buy.itunes.apple.com"
        case .lookup, .search:
            return "itunes.apple.com"
        }
    }

    private var path: String {
        switch self {
        case let .authenticate(_, guid, useLegacy):
            if useLegacy {
                return "/WebObjects/MZFinance.woa/wa/authenticate"
            } else {
                return "/auth/v1/native/fast"
            }
        case .buy:
            return "/WebObjects/MZBuy.woa/wa/buyProduct"
        case .download:
            return "/WebObjects/MZFinance.woa/wa/volumeStoreDownloadProduct"
        case .lookup:
            return "/lookup"
        case .search:
            return "/search"
        }
    }
    
    private var queryItems: [URLQueryItem]? {
        switch self {
        case let .authenticate(_, guid, _):
            return [URLQueryItem(name: "guid", value: guid)]
        case let .download(guid, _):
            return [URLQueryItem(name: "guid", value: guid)]
        case let .lookup(bundleId, country):
            return [
                URLQueryItem(name: "bundleId", value: bundleId),
                URLQueryItem(name: "country", value: country)
            ]
        case let .search(term, country, limit):
            return [
                URLQueryItem(name: "term", value: term),
                URLQueryItem(name: "country", value: country),
                URLQueryItem(name: "limit", value: String(limit)),
                URLQueryItem(name: "media", value: "software")
            ]
        case .buy:
            return nil
        }
    }
}

/// 向后兼容的StoreEndpoint扩展
extension StoreEndpoint {
    /// 转换为增强版本
    func toEnhanced() -> EnhancedStoreEndpoint {
        switch self {
        case let .authenticate(prefix, guid):
            return .authenticate(prefix: prefix.isEmpty ? nil : prefix, guid: guid, useLegacy: !prefix.isEmpty)
        case let .download(guid):
            return .download(guid: guid)
        case .buy:
            return .buy()
        }
    }
    
    /// 使用增强版本的URL
    var enhancedURL: URL {
        return toEnhanced().url
    }
}

/// Store端点配置管理器
class StoreEndpointManager {
    static let shared = StoreEndpointManager()
    
    private var preferredRegion: String?
    private var useLegacyAuth: Bool = false
    
    private init() {}
    
    /// 设置首选区域
    func setPreferredRegion(_ region: String?) {
        self.preferredRegion = region
    }
    
    /// 设置是否使用传统认证
    func setUseLegacyAuth(_ useLegacy: Bool) {
        self.useLegacyAuth = useLegacy
    }
    
    /// 获取认证端点
    func authenticationEndpoint(prefix: String?, guid: String) -> EnhancedStoreEndpoint {
        return .authenticate(prefix: prefix, guid: guid, useLegacy: useLegacyAuth)
    }
    
    /// 获取下载端点
    func downloadEndpoint(guid: String) -> EnhancedStoreEndpoint {
        return .download(guid: guid, region: preferredRegion)
    }
    
    /// 获取购买端点
    func buyEndpoint() -> EnhancedStoreEndpoint {
        return .buy(region: preferredRegion)
    }
    
    /// 获取应用查找端点
    func lookupEndpoint(bundleId: String, country: String = "US") -> EnhancedStoreEndpoint {
        return .lookup(bundleId: bundleId, country: country)
    }
    
    /// 获取应用搜索端点
    func searchEndpoint(term: String, country: String = "US", limit: Int = 50) -> EnhancedStoreEndpoint {
        return .search(term: term, country: country, limit: limit)
    }
}

/// 端点性能监控
class StoreEndpointMonitor {
    static let shared = StoreEndpointMonitor()
    
    private var responseTimeCache: [String: TimeInterval] = [:]
    private var failureCount: [String: Int] = [:]
    
    private init() {}
    
    /// 记录响应时间
    func recordResponseTime(_ time: TimeInterval, for endpoint: String) {
        responseTimeCache[endpoint] = time
    }
    
    /// 记录失败
    func recordFailure(for endpoint: String) {
        failureCount[endpoint, default: 0] += 1
    }
    
    /// 获取最佳端点（基于性能）
    func getBestEndpoint(for type: String, alternatives: [String]) -> String? {
        return alternatives.min { endpoint1, endpoint2 in
            let time1 = responseTimeCache[endpoint1] ?? TimeInterval.infinity
            let time2 = responseTimeCache[endpoint2] ?? TimeInterval.infinity
            let failures1 = failureCount[endpoint1] ?? 0
            let failures2 = failureCount[endpoint2] ?? 0
            
            // 优先选择失败次数少的，然后是响应时间短的
            if failures1 != failures2 {
                return failures1 < failures2
            }
            return time1 < time2
        }
    }
    
    /// 清理缓存
    func clearCache() {
        responseTimeCache.removeAll()
        failureCount.removeAll()
    }
}
//
//  VersionQueryService.swift
//  版本查询服务
//  集成多个App Store版本查询API接口

import Foundation
import Combine

/// 版本查询服务类
public class VersionQueryService: ObservableObject {
    public static let shared = VersionQueryService()
    
    private let urlSession = URLSession.shared
    private var cancellables = Set<AnyCancellable>()
    
    private init() {}
    
    /// API端点枚举
    public enum APIEndpoint {
        case timbrd     // 最快的接口
        case bilin      // 数据更完善但可能较慢
        case agzy       // 苹果官方数据
        
        func url(for appId: String) -> URL? {
            let urlString: String
            switch self {
            case .timbrd:
                urlString = "https://api.timbrd.com/apple/app-version/index.php?id=\(appId)"
            case .bilin:
                urlString = "https://apis.bilin.eu.org/history/\(appId)"
            case .agzy:
                urlString = "https://app.agzy.cn/searchVersion?appid=\(appId)"
            }
            return URL(string: urlString)
        }
    }
    
    /// 版本信息结构体
    public struct VersionInfo: Codable, Identifiable {
        public let id = UUID()
        public let version: String
        public let releaseDate: String?
        public let releaseNotes: String?
        public let bundleId: String?
        public let fileSize: Int64?
        
        enum CodingKeys: String, CodingKey {
            case version
            case releaseDate = "release_date"
            case releaseNotes = "release_notes"
            case bundleId = "bundle_id"
            case fileSize = "file_size"
        }
    }
    
    /// 查询结果结构体
    public struct QueryResult {
        public let appId: String
        public let versions: [VersionInfo]
        public let source: APIEndpoint
        public let success: Bool
        public let error: Error?
    }
    
    /// 查询App版本信息
    /// - Parameters:
    ///   - appId: App Store ID
    ///   - preferredEndpoint: 首选API端点，默认为timbrd（最快）
    ///   - completion: 完成回调
    public func queryVersions(
        for appId: String,
        preferredEndpoint: APIEndpoint = .timbrd,
        completion: @escaping (QueryResult) -> Void
    ) {
        // 首先尝试首选端点
        queryFromEndpoint(appId: appId, endpoint: preferredEndpoint) { result in
            if result.success {
                completion(result)
            } else {
                // 如果首选端点失败，尝试其他端点
                self.fallbackQuery(appId: appId, excludeEndpoint: preferredEndpoint, completion: completion)
            }
        }
    }
    
    /// 从指定端点查询版本信息
    private func queryFromEndpoint(
        appId: String,
        endpoint: APIEndpoint,
        completion: @escaping (QueryResult) -> Void
    ) {
        guard let url = endpoint.url(for: appId) else {
            let error = NSError(domain: "VersionQueryService", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "无效的URL"
            ])
            completion(QueryResult(appId: appId, versions: [], source: endpoint, success: false, error: error))
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = endpoint == .bilin ? 10.0 : 5.0 // bilin接口可能较慢，给更长超时时间
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        
        urlSession.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(QueryResult(appId: appId, versions: [], source: endpoint, success: false, error: error))
                    return
                }
                
                guard let data = data else {
                    let error = NSError(domain: "VersionQueryService", code: -2, userInfo: [
                        NSLocalizedDescriptionKey: "无数据返回"
                    ])
                    completion(QueryResult(appId: appId, versions: [], source: endpoint, success: false, error: error))
                    return
                }
                
                do {
                    let versions = try self.parseResponse(data: data, endpoint: endpoint)
                    completion(QueryResult(appId: appId, versions: versions, source: endpoint, success: true, error: nil))
                } catch {
                    completion(QueryResult(appId: appId, versions: [], source: endpoint, success: false, error: error))
                }
            }
        }.resume()
    }
    
    /// 备用查询，当首选端点失败时使用
    private func fallbackQuery(
        appId: String,
        excludeEndpoint: APIEndpoint,
        completion: @escaping (QueryResult) -> Void
    ) {
        let allEndpoints: [APIEndpoint] = [.timbrd, .bilin, .agzy]
        let fallbackEndpoints = allEndpoints.filter { $0 != excludeEndpoint }
        
        var currentIndex = 0
        
        func tryNextEndpoint() {
            guard currentIndex < fallbackEndpoints.count else {
                // 所有端点都失败了
                let error = NSError(domain: "VersionQueryService", code: -3, userInfo: [
                    NSLocalizedDescriptionKey: "所有API端点都无法访问"
                ])
                completion(QueryResult(appId: appId, versions: [], source: excludeEndpoint, success: false, error: error))
                return
            }
            
            let endpoint = fallbackEndpoints[currentIndex]
            currentIndex += 1
            
            queryFromEndpoint(appId: appId, endpoint: endpoint) { result in
                if result.success {
                    completion(result)
                } else {
                    tryNextEndpoint()
                }
            }
        }
        
        tryNextEndpoint()
    }
    
    /// 解析不同API的响应数据
    private func parseResponse(data: Data, endpoint: APIEndpoint) throws -> [VersionInfo] {
        switch endpoint {
        case .timbrd:
            return try parseTimbrdResponse(data: data)
        case .bilin:
            return try parseBilinResponse(data: data)
        case .agzy:
            return try parseAgzyResponse(data: data)
        }
    }
    
    /// 解析Timbrd API响应
    private func parseTimbrdResponse(data: Data) throws -> [VersionInfo] {
        // 根据实际API响应格式调整
        struct TimbrdResponse: Codable {
            let versions: [TimbrdVersion]?
            let data: [TimbrdVersion]?
        }
        
        struct TimbrdVersion: Codable {
            let version: String
            let releaseDate: String?
            let releaseNotes: String?
            
            enum CodingKeys: String, CodingKey {
                case version
                case releaseDate = "release_date"
                case releaseNotes = "release_notes"
            }
        }
        
        let response = try JSONDecoder().decode(TimbrdResponse.self, from: data)
        let timbrdVersions = response.versions ?? response.data ?? []
        
        return timbrdVersions.map { timbrdVersion in
            VersionInfo(
                version: timbrdVersion.version,
                releaseDate: timbrdVersion.releaseDate,
                releaseNotes: timbrdVersion.releaseNotes,
                bundleId: nil,
                fileSize: nil
            )
        }
    }
    
    /// 解析Bilin API响应
    private func parseBilinResponse(data: Data) throws -> [VersionInfo] {
        // 根据实际API响应格式调整
        struct BilinResponse: Codable {
            let history: [BilinVersion]?
            let data: [BilinVersion]?
        }
        
        struct BilinVersion: Codable {
            let version: String
            let releaseDate: String?
            let releaseNotes: String?
            let bundleId: String?
            let fileSize: Int64?
            
            enum CodingKeys: String, CodingKey {
                case version
                case releaseDate = "release_date"
                case releaseNotes = "release_notes"
                case bundleId = "bundle_id"
                case fileSize = "file_size"
            }
        }
        
        let response = try JSONDecoder().decode(BilinResponse.self, from: data)
        let bilinVersions = response.history ?? response.data ?? []
        
        return bilinVersions.map { bilinVersion in
            VersionInfo(
                version: bilinVersion.version,
                releaseDate: bilinVersion.releaseDate,
                releaseNotes: bilinVersion.releaseNotes,
                bundleId: bilinVersion.bundleId,
                fileSize: bilinVersion.fileSize
            )
        }
    }
    
    /// 解析Agzy API响应
    private func parseAgzyResponse(data: Data) throws -> [VersionInfo] {
        // 根据实际API响应格式调整
        struct AgzyResponse: Codable {
            let versions: [AgzyVersion]?
            let data: [AgzyVersion]?
        }
        
        struct AgzyVersion: Codable {
            let version: String
            let releaseDate: String?
            let releaseNotes: String?
            let bundleId: String?
            
            enum CodingKeys: String, CodingKey {
                case version
                case releaseDate = "release_date"
                case releaseNotes = "release_notes"
                case bundleId = "bundle_id"
            }
        }
        
        let response = try JSONDecoder().decode(AgzyResponse.self, from: data)
        let agzyVersions = response.versions ?? response.data ?? []
        
        return agzyVersions.map { agzyVersion in
            VersionInfo(
                version: agzyVersion.version,
                releaseDate: agzyVersion.releaseDate,
                releaseNotes: agzyVersion.releaseNotes,
                bundleId: agzyVersion.bundleId,
                fileSize: nil
            )
        }
    }
    
    /// Combine版本的查询方法
    func queryVersionsPublisher(
        for appId: String,
        preferredEndpoint: APIEndpoint = .timbrd
    ) -> AnyPublisher<QueryResult, Never> {
        return Future<QueryResult, Never> { promise in
            self.queryVersions(for: appId, preferredEndpoint: preferredEndpoint) { result in
                promise(.success(result))
            }
        }
        .eraseToAnyPublisher()
    }
    
    /// Async/await版本的查询方法
    func queryVersions(
        appId: String,
        preferredEndpoint: APIEndpoint = .timbrd
    ) async throws -> QueryResult {
        return await withCheckedContinuation { continuation in
            queryVersions(for: appId, preferredEndpoint: preferredEndpoint) { result in
                continuation.resume(returning: result)
            }
        }
    }
}

/// 版本查询服务扩展 - 便捷方法
extension VersionQueryService {
    /// 快速查询最新版本
    func queryLatestVersion(
        for appId: String,
        completion: @escaping (String?) -> Void
    ) {
        queryVersions(for: appId) { result in
            let latestVersion = result.versions.first?.version
            completion(latestVersion)
        }
    }
    
    /// 检查是否有指定版本
    func hasVersion(
        _ version: String,
        for appId: String,
        completion: @escaping (Bool) -> Void
    ) {
        queryVersions(for: appId) { result in
            let hasVersion = result.versions.contains { $0.version == version }
            completion(hasVersion)
        }
    }
}
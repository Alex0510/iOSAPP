//
//  AppVersionQueryService.swift
//  of pxx917144686
//
//  App Store版本查询服务
//

import Foundation
import Combine

/// App版本信息结构
struct AppVersionInfo: Identifiable, Hashable {
    let id = UUID()
    let version: String
    let versionId: String
    let source: String // "i4cn", "bilin", "timbrd"
}

/// 当前版本信息
struct CurrentVersionInfo: Codable {
    let version: String?
    let versionId: String?
    
    enum CodingKeys: String, CodingKey {
        case version, versionId = "versionid"
    }
}

/// 查询结果
struct AppVersionQueryResult {
    let appId: String
    let appName: String
    let currentVersion: CurrentVersionInfo?
    let historyVersions: [AppVersionInfo]
    let sources: [String]
    let queryTime: Date
}

/// App Store版本查询服务
class AppVersionQueryService: ObservableObject {
    static let shared = AppVersionQueryService()
    
    @Published var isLoading = false
    @Published var lastResult: AppVersionQueryResult?
    @Published var errorMessage: String?
    
    private let session: URLSession
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10.0
        config.timeoutIntervalForResource = 30.0
        self.session = URLSession(configuration: config)
    }
    
    /// 从App Store URL查询版本信息
    func queryVersions(from appStoreURL: String) -> AnyPublisher<AppVersionQueryResult, Error> {
        guard let (appId, appName) = extractAppInfo(from: appStoreURL) else {
            return Fail(error: AppVersionQueryError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        return queryVersions(appId: appId, appName: appName)
    }
    
    /// 查询指定App ID的版本信息
    func queryVersions(appId: String, appName: String) -> AnyPublisher<AppVersionQueryResult, Error> {
        isLoading = true
        errorMessage = nil
        
        let i4cnPublisher = fetchI4CNVersions(appId: appId, appName: appName)
        let bilinPublisher = fetchBilinVersions(appId: appId)
        let timbrdPublisher = fetchTimbrdVersions(appId: appId)
        
        return Publishers.Zip3(i4cnPublisher, bilinPublisher, timbrdPublisher)
            .map { i4cnResult, bilinVersions, timbrdVersions in
                let allVersions = self.mergeAndDeduplicate(
                    i4cnVersions: i4cnResult.history,
                    bilinVersions: bilinVersions,
                    timbrdVersions: timbrdVersions
                )
                
                let sources = ["i4cn", "bilin", "timbrd"].filter { source in
                    switch source {
                    case "i4cn": return !i4cnResult.history.isEmpty
                    case "bilin": return !bilinVersions.isEmpty
                    case "timbrd": return !timbrdVersions.isEmpty
                    default: return false
                    }
                }
                
                return AppVersionQueryResult(
                    appId: appId,
                    appName: appName,
                    currentVersion: i4cnResult.current,
                    historyVersions: allVersions,
                    sources: sources,
                    queryTime: Date()
                )
            }
            .handleEvents(
                receiveOutput: { [weak self] result in
                    DispatchQueue.main.async {
                        self?.lastResult = result
                        self?.isLoading = false
                    }
                },
                receiveCompletion: { [weak self] completion in
                    DispatchQueue.main.async {
                        self?.isLoading = false
                        if case .failure(let error) = completion {
                            self?.errorMessage = error.localizedDescription
                        }
                    }
                }
            )
            .eraseToAnyPublisher()
    }
    
    // MARK: - Private Methods
    
    /// 从App Store URL提取App ID和名称
    private func extractAppInfo(from url: String) -> (appId: String, appName: String)? {
        let idPattern = #"id(\d+)"#
        let namePattern = #"/app/([^/?]+)"#
        
        guard let idRegex = try? NSRegularExpression(pattern: idPattern),
              let nameRegex = try? NSRegularExpression(pattern: namePattern) else {
            return nil
        }
        
        let range = NSRange(location: 0, length: url.utf16.count)
        
        guard let idMatch = idRegex.firstMatch(in: url, range: range),
              let nameMatch = nameRegex.firstMatch(in: url, range: range) else {
            return nil
        }
        
        let appId = String(url[Range(idMatch.range(at: 1), in: url)!])
        let encodedName = String(url[Range(nameMatch.range(at: 1), in: url)!])
        let appName = encodedName.removingPercentEncoding ?? encodedName
        
        return (appId, appName)
    }
    
    /// 获取I4CN版本信息
    private func fetchI4CNVersions(appId: String, appName: String) -> AnyPublisher<(current: CurrentVersionInfo?, history: [AppVersionInfo]), Error> {
        let encodedName = appName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? appName
        let searchURL = "https://search-app-m.i4.cn/getAppList.xhtml?keyword=\(encodedName)&model=iPhone&osversion=14.3&toolversion=100&pagesize=100&pageno=1"
        
        guard let url = URL(string: searchURL) else {
            return Just((current: nil, history: []))
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: I4CNSearchResponse.self, decoder: JSONDecoder())
            .flatMap { [weak self] searchResponse -> AnyPublisher<(current: CurrentVersionInfo?, history: [AppVersionInfo]), Error> in
                guard let self = self,
                      let matchedApp = self.findMatchedApp(in: searchResponse, appId: appId, appName: appName.lowercased()) else {
                    return Just((current: nil, history: []))
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                
                let detailURL = "https://app4.i4.cn/appinfo.xhtml?appid=\(matchedApp.id)&from=1"
                guard let detailURLObj = URL(string: detailURL) else {
                    return Just((current: nil, history: []))
                        .setFailureType(to: Error.self)
                        .eraseToAnyPublisher()
                }
                
                return self.session.dataTaskPublisher(for: detailURLObj)
                    .map(\.data)
                    .decode(type: I4CNDetailResponse.self, decoder: JSONDecoder())
                    .map { detailResponse in
                        let current = CurrentVersionInfo(
                            version: detailResponse.version,
                            versionId: detailResponse.versionId
                        )
                        
                        let history = detailResponse.historyVersions?.map { historyVersion in
                            AppVersionInfo(
                                version: historyVersion.version,
                                versionId: historyVersion.versionId,
                                source: "i4cn"
                            )
                        } ?? []
                        
                        return (current: current, history: history)
                    }
                    .eraseToAnyPublisher()
            }
            .catch { _ in
                Just((current: nil, history: []))
                    .setFailureType(to: Error.self)
            }
            .eraseToAnyPublisher()
    }
    
    /// 获取Bilin版本信息
    private func fetchBilinVersions(appId: String) -> AnyPublisher<[AppVersionInfo], Error> {
        let urlString = "https://apis.bilin.eu.org/history/\(appId)"
        guard let url = URL(string: urlString) else {
            return Just([])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: BilinResponse.self, decoder: JSONDecoder())
            .map { response in
                response.data?.map { item in
                    AppVersionInfo(
                        version: item.bundleVersion ?? item.version ?? "",
                        versionId: item.externalIdentifier ?? item.versionId ?? "",
                        source: "bilin"
                    )
                }.filter { !$0.version.isEmpty && !$0.versionId.isEmpty } ?? []
            }
            .catch { _ in Just([]).setFailureType(to: Error.self) }
            .eraseToAnyPublisher()
    }
    
    /// 获取Timbrd版本信息
    private func fetchTimbrdVersions(appId: String) -> AnyPublisher<[AppVersionInfo], Error> {
        let urlString = "https://api.timbrd.com/apple/app-version/index.php?id=\(appId)"
        guard let url = URL(string: urlString) else {
            return Just([])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        
        return session.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [TimbrdVersionInfo].self, decoder: JSONDecoder())
            .map { versions in
                versions.map { item in
                    AppVersionInfo(
                        version: item.bundleVersion ?? item.version ?? "",
                        versionId: item.externalIdentifier ?? item.versionId ?? "",
                        source: "timbrd"
                    )
                }.filter { !$0.version.isEmpty && !$0.versionId.isEmpty }
            }
            .catch { _ in Just([]).setFailureType(to: Error.self) }
            .eraseToAnyPublisher()
    }
    
    /// 查找匹配的应用
    private func findMatchedApp(in response: I4CNSearchResponse, appId: String, appName: String) -> I4CNApp? {
        // 首先按ID匹配
        if let matchedApp = response.app?.first(where: { String($0.itemId) == appId }) {
            return matchedApp
        }
        
        // 然后按名称匹配
        return response.app?.first { app in
            app.softName.lowercased().contains(appName)
        }
    }
    
    /// 合并和去重版本信息
    private func mergeAndDeduplicate(
        i4cnVersions: [AppVersionInfo],
        bilinVersions: [AppVersionInfo],
        timbrdVersions: [AppVersionInfo]
    ) -> [AppVersionInfo] {
        var versionMap: [String: AppVersionInfo] = [:]
        
        let allVersions = i4cnVersions + bilinVersions + timbrdVersions
        
        for version in allVersions {
            let key = "\(version.version)::\(version.versionId)"
            if versionMap[key] == nil {
                versionMap[key] = version
            }
        }
        
        return Array(versionMap.values).sorted { v1, v2 in
            // 尝试按版本号排序
            return v1.version.compare(v2.version, options: .numeric) == .orderedDescending
        }
    }
}

// MARK: - Response Models

struct I4CNSearchResponse: Codable {
    let app: [I4CNApp]?
}

struct I4CNApp: Codable {
    let id: Int
    let itemId: Int
    let softName: String
    
    enum CodingKeys: String, CodingKey {
        case id, itemId = "itemid", softName = "softname"
    }
}

struct I4CNDetailResponse: Codable {
    let version: String?
    let versionId: String?
    let historyVersions: [I4CNHistoryVersion]?
    
    enum CodingKeys: String, CodingKey {
        case version = "Version", versionId = "versionid", historyVersions = "historyversion"
    }
}

struct I4CNHistoryVersion: Codable {
    let version: String
    let versionId: String
    
    enum CodingKeys: String, CodingKey {
        case version = "Version", versionId = "versionid"
    }
}

struct BilinResponse: Codable {
    let data: [BilinVersionInfo]?
}

struct BilinVersionInfo: Codable {
    let bundleVersion: String?
    let version: String?
    let externalIdentifier: String?
    let versionId: String?
    
    enum CodingKeys: String, CodingKey {
        case bundleVersion = "bundle_version"
        case version
        case externalIdentifier = "external_identifier"
        case versionId = "versionid"
    }
}

struct TimbrdVersionInfo: Codable {
    let bundleVersion: String?
    let version: String?
    let externalIdentifier: String?
    let versionId: String?
    
    enum CodingKeys: String, CodingKey {
        case bundleVersion = "bundle_version"
        case version
        case externalIdentifier = "external_identifier"
        case versionId = "versionid"
    }
}

// MARK: - Error Types

enum AppVersionQueryError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case noDataFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的App Store URL"
        case .networkError(let error):
            return "网络错误: \(error.localizedDescription)"
        case .decodingError(let error):
            return "数据解析错误: \(error.localizedDescription)"
        case .noDataFound:
            return "未找到版本信息"
        }
    }
}
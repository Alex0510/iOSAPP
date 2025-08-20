// 导入 Foundation 框架，提供基本的核心功能
import Foundation
// 导入 Combine 框架，用于处理异步事件流
import Combine

// 版本管理类，负责获取应用的版本 ID
class VersionManager {
    // 私有属性，存储 StoreClient 实例
    private let storeClient: StoreClient
    
    // 初始化方法，传入 Apple ID 和密码创建 StoreClient 实例
    init(appleId: String, password: String) {
        self.storeClient = StoreClient(appleId: appleId, password: password)
    }
    
    // 获取指定应用 ID 的版本 ID 列表
    // 参数: appId - 应用的 ID
    // 返回: 一个 Future，异步返回版本 ID 数组或错误
    func getVersionIDs(appId: String) -> Future<[String], Error> {
        return Future { promise in
            // 在全局队列中异步执行任务
            DispatchQueue.global().async {
                // 尝试进行身份验证
                if !self.storeClient.authenticate() {
                    // 身份验证失败，返回认证失败错误
                    promise(.failure(VersionError.authenticationFailed))
                    return
                }
                
                // 尝试下载应用数据
                guard let response = self.storeClient.download(appId: appId, isRedownload: true) else {
                    // 下载失败，返回请求失败错误
                    promise(.failure(VersionError.requestFailed))
                    return
                }
                
                // 解析下载的响应数据，获取版本 ID 列表
                let versions = self.parseVersionResponse(response, appId: appId)
                // 返回解析成功的版本 ID 列表
                promise(.success(versions))
            }
        }
    }
    
    // 解析下载响应数据，提取版本 ID
    // 参数:
    // - response: 下载响应数据，字典类型
    // - appId: 应用的 ID
    // 返回: 解析得到的版本 ID 数组
    private func parseVersionResponse(_ response: [String: Any], appId: String) -> [String] {
        // 逐步解包响应数据，获取版本 ID 数组
        guard let songList = response["songList"] as? [[String: Any]],
              !songList.isEmpty,
              let metadata = songList[0]["metadata"] as? [String: Any],
              let versionIds = metadata["softwareVersionExternalIdentifiers"] as? [Int] else {
            // 解包失败，返回空数组
            return []
        }
        
        // 将 Int 类型的版本 ID 转换为 String 类型
        return versionIds.map { String($0) }
    }
}

// 自定义错误枚举，用于表示版本管理过程中可能出现的错误
enum VersionError: Error {
    // 身份验证失败
    case authenticationFailed
    // 请求失败
    case requestFailed
    // 解析失败
    case parsingFailed
}
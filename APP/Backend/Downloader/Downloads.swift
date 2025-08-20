import AnyCodable    // 支持任何类型的Codable
import ApplePackage  // Apple包处理库
import Combine       // 响应式编程框架
import Digger        // 下载管理器库
import Foundation    // 基础框架

private func extractVersionFromIPA(url: URL) -> String? {
    // TODO: 实现从IPA文件中提取版本号的逻辑
    return nil
}

/// 字节格式化器，用于格式化文件大小显示
private let byteFormatter: ByteCountFormatter = {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useAll]  // 设置允许使用所有单位
    formatter.countStyle = .file  // 设置计数样式为文件大小
    return formatter
}()

/// 下载管理器类，管理应用中的所有下载任务
/// 遵循ObservableObject协议，支持UI响应式更新
class Downloads: ObservableObject {
    /// 单例实例，全局访问点
      static let this = Downloads()

    /// 下载请求列表，持久化存储
    @PublishedPersist(key: "DownloadRequests", defaultValue: [])
    var requests: [Request]

    /// 正在运行的任务数量
    var runningTaskCount: Int {
        requests.filter { $0.runtime.status == .downloading }.count
    }

    /// 初始化方法
    /// 设置下载管理器的配置和状态
    init() {
        let copy = requests
        // 遍历未完成的下载请求，将其状态设置为停止
        for req in copy where !isCompleted(for: req) {
            alter(reqID: req.id) { req in
                req.runtime.status = .stopped
            }
        }

        // 设置下载管理器的最大并发任务数为4
        DiggerManager.shared.maxConcurrentTasksCount = 4
        // 设置下载管理器的超时时间为15秒
        DiggerManager.shared.timeout = 15
    }

    /// 检查下载请求是否已完成
    func isCompleted(for request: Request) -> Bool {
        // 检查目标文件是否存在，若存在则报告成功并返回已完成
        if FileManager.default.fileExists(atPath: request.targetLocation.path) {
            reportSuccess(reqId: request.id)
            return true
        }
        return false
    }

    /// 添加新的下载请求
    @discardableResult
    func add(request: Request) -> Request.ID {
        if Thread.isMainThread {
            // 若在主线程，直接插入新请求到列表开头
            requests.insert(request, at: 0)
            return request.id
        } else {
            // 若不在主线程，异步切换到主线程插入新请求
            DispatchQueue.main.asyncAndWait {
                self.requests.insert(request, at: 0)
            }
            return request.id
        }
    }
    
    /// 添加带版本选择的下载请求
    @discardableResult
    func add(request: Request, version: String?) throws -> Request.ID {
        // 检查版本是否为空，若为空则抛出需要选择版本的错误
        guard let version = version else {
            throw VersionError.versionSelectionRequired
        }
        
        var modifiedRequest = request
        modifiedRequest.version = version  // 设置请求的版本
        
        if Thread.isMainThread {
            // 若在主线程，直接插入修改后的请求到列表开头
            requests.insert(modifiedRequest, at: 0)
            return modifiedRequest.id
        } else {
            // 若不在主线程，异步切换到主线程插入修改后的请求
            DispatchQueue.main.asyncAndWait {
                self.requests.insert(modifiedRequest, at: 0)
            }
            return modifiedRequest.id
        }
    }

    /// 格式化字节数为可读字符串
    func byteFormat(bytes: Int64) -> String {
        if bytes > 0 {
            // 若字节数大于0，使用字节格式化器进行格式化
            return byteFormatter.string(fromByteCount: bytes)
        }
        return ""  // 若字节数不大于0，返回空字符串
    }

    /// 暂停下载请求
    func suspend(requestID: Request.ID) {
        // 根据请求ID查找对应的下载请求
        let request = requests.first(where: { $0.id == requestID })
        guard let request else { return }
        // 若请求已完成，则不进行操作
        if isCompleted(for: request) { return }
        // 调用下载管理器停止该请求对应的任务
        DiggerManager.shared.stopTask(for: request.url)
        // 等待回调触发，0.1秒后更新请求状态
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            self.alter(reqID: requestID) { req in
                req.runtime.status = .stopped  // 设置请求状态为停止
                req.runtime.error = nil  // 清除错误信息
                req.runtime.speed = ""  // 清除下载速度
                req.runtime.percent = 0  // 重置下载进度
            }
        }
    }

    /// 恢复下载请求
    func resume(requestID: Request.ID) {
        // 根据请求ID查找对应的下载请求
        let request = requests.first(where: { $0.id == requestID })
        guard let request else { return }
        // 若请求已完成，则不进行操作
        if isCompleted(for: request) { return }

        // 更新请求状态为待处理
        alter(reqID: requestID) { req in
            req.runtime.status = .pending  // 设置请求状态为待处理
            req.runtime.error = nil  // 清除错误信息
            req.runtime.speed = ""  // 清除下载速度
            req.runtime.percent = 0  // 重置下载进度
        }
        // 异步执行下载操作
        DispatchQueue.global().async {
            DiggerManager.shared.download(with: request.url)
                .speed { speedInput in
                    // 格式化下载速度并报告
                    let speed = self.byteFormat(bytes: speedInput)
                    self.report(speed: speed, reqId: requestID)
                }
                .progress { progress in
                    // 报告下载进度
                    self.report(progress: progress, reqId: requestID)
                }
                .completion { output in
                    DispatchQueue.global().async {
                        switch output {
                        case let .success(url):
                            // 下载成功，报告正在验证并处理下载完成的文件
                            self.reportValidating(reqId: requestID)
                            self.finalize(request: request, url: url)
                        case let .failure(error):
                            // 下载失败，报告错误信息
                            self.report(error: error, reqId: requestID)
                        }
                    }
                }
        }
    }

    /// 处理下载完成的文件
    /// 包括验证、移动和添加元数据
    func finalize(request: Request, url: URL) {
        // 如果请求指定了版本，验证下载的版本是否匹配
        if let version = request.version {
            guard let downloadedVersion = extractVersionFromIPA(url: url),
                  downloadedVersion == version else {
                // 版本不匹配，报告版本未找到的错误
                report(error: NSError(domain: "Version", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: NSLocalizedString("Version mismatch", comment: "")
                ]), reqId: request.id)
                return
            }
        }
        let targetLocation = request.targetLocation

        do {
            let md5 = request.md5
            let fileMD5 = md5File(url: url)
            // 验证MD5值是否匹配
            guard md5.lowercased() == fileMD5?.lowercased() else {
                // MD5值不匹配，报告MD5不匹配的错误
                report(error: NSError(domain: "MD5", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: NSLocalizedString("MD5 mismatch", comment: ""),
                ]), reqId: request.id)
                return
            }

            // 尝试删除目标位置已存在的文件
            try? FileManager.default.removeItem(at: targetLocation)
            // 尝试创建目标位置的目录
            try? FileManager.default.createDirectory(
                at: targetLocation.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            // 将下载的文件移动到目标位置
            try FileManager.default.moveItem(at: url, to: targetLocation)
            // 编码请求的元数据
            let data = try JSONEncoder().encode(request.metadata)
            // 解码元数据为字典
            let object = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]

            print("[*] sending metadata into \(targetLocation.path)")
            // 创建存储响应项
            let item = StoreResponse.Item(
                url: request.url,
                md5: request.md5,
                signatures: request.signatures,
                metadata: object
            )
            // 创建签名客户端
            let signatureClient = SignatureClient(fileManager: .default, filePath: targetLocation.path)
            // 尝试追加元数据
            try signatureClient.appendMetadata(item: item, email: request.account.email)
            // 尝试追加签名
            try signatureClient.appendSignature(item: item)

            // 报告下载成功
            reportSuccess(reqId: request.id)
        } catch {
            // 出现错误，尝试删除目标位置的文件并报告错误
            try? FileManager.default.removeItem(at: targetLocation)
            report(error: error, reqId: request.id)
        }
    }

    /// 删除下载请求及其文件
    func delete(request: Request) {
        DispatchQueue.main.async { [self] in
            // 取消该请求对应的下载任务
            DiggerManager.shared.cancelTask(for: request.url)
            // 移除该请求对应的下载种子
            DiggerManager.shared.removeDigeerSeed(for: request.url)
            // 从请求列表中移除该请求
            requests.removeAll { $0.id == request.id }
            // 尝试删除目标位置的文件
            try? FileManager.default.removeItem(at: request.targetLocation)
        }
    }

    /// 恢复所有下载请求
    func resumeAll() {
        // 遍历所有下载请求，逐个恢复
        for req in requests {
            resume(requestID: req.id)
        }
    }

    /// 暂停所有下载请求
    func suspendAll() {
        // 调用下载管理器停止所有任务
        DiggerManager.shared.stopAllTasks()
    }

    /// 删除所有下载请求及其文件
    func removeAll() {
        let copy = requests
        // 遍历所有下载请求，逐个删除
        for req in copy {
            delete(request: req)
        }
    }

    /// 根据iTunes归档查找下载请求
    func downloadRequest(forArchive archive: iTunesResponse.iTunesArchive) -> Request? {
        // 遍历所有下载请求，查找匹配的请求
        for req in requests {
            if req.package == archive {
                return req
            }
        }
        return nil  // 未找到匹配请求，返回nil
    }
}

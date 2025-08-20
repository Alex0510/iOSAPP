// 导入必要的框架
import AnyCodable
import ApplePackage
import Combine
import Digger
import Foundation

/// 字节格式化器：用于将字节数转换为可读的文件大小字符串
private let byteFormatter: ByteCountFormatter = {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useAll]  // 允许使用所有单位
    formatter.countStyle = .file        // 使用文件计数样式
    return formatter
}()

/// 下载管理器：负责管理应用中的所有下载任务
class Downloads: ObservableObject {
    /// 单例实例：全局访问点
    static let this = Downloads()

    /// 下载请求数组：使用PublishedPersist属性包装器持久化存储
    @PublishedPersist(key: "DownloadRequests", defaultValue: [])
    var requests: [Request]

    /// 正在运行的任务数量
    var runningTaskCount: Int {
        // 过滤出状态为下载中的请求
        requests.filter { $0.runtime.status == .downloading }.count
    }

    /// 初始化方法：设置下载管理器
    init() {
        // 复制请求数组，避免在遍历时修改
        let copy = requests
        // 遍历所有未完成的请求
        for req in copy where !isCompleted(for: req) {
            // 将未完成请求的状态设置为已停止
            alter(reqID: req.id) { req in
                req.runtime.status = .stopped
            }
        }

        // 设置最大并发任务数为4
        DiggerManager.shared.maxConcurrentTasksCount = 4
        // 设置超时时间为15秒
        DiggerManager.shared.timeout = 15
    }

    /// 检查下载请求是否已完成
    /// - Parameter request: 要检查的下载请求
    /// - Returns: 如果文件已存在且MD5匹配则返回true，否则返回false
    func isCompleted(for request: Request) -> Bool {
        // 检查目标文件是否存在
        if FileManager.default.fileExists(atPath: request.targetLocation.path) {
            // 报告下载成功
            reportSuccess(reqId: request.id)
            return true
        }
        return false
    }

    /// 添加新的下载请求
    /// - Parameter request: 要添加的下载请求
    /// - Returns: 下载请求的ID
    @discardableResult
    func add(request: Request) -> Request.ID {
        // 检查是否在主线程
        if Thread.isMainThread {
            // 在主线程直接插入请求
            requests.insert(request, at: 0)
            return request.id
        } else {
            // 在非主线程使用异步方式插入请求
            DispatchQueue.main.asyncAndWait {
                self.requests.insert(request, at: 0)
            }
            return request.id
        }
    }

    /// 将字节数格式化为可读的文件大小字符串
    /// - Parameter bytes: 字节数
    /// - Returns: 格式化后的文件大小字符串
    func byteFormat(bytes: Int64) -> String {
        // 如果字节数大于0，则格式化
        if bytes > 0 {
            return byteFormatter.string(fromByteCount: bytes)
        }
        // 否则返回空字符串
        return ""
    }

    /// 暂停下载请求
    /// - Parameter requestID: 要暂停的请求ID
    func suspend(requestID: Request.ID) {
        // 查找指定ID的请求
        let request = requests.first(where: { $0.id == requestID })
        // 如果请求不存在，则返回
        guard let request else { return }
        // 如果请求已完成，则返回
        // 如果请求已完成，则返回
        if isCompleted(for: request) { return }
        // 停止下载任务
        DiggerManager.shared.stopTask(for: request.url)
        // 等待回调触发
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            self.alter(reqID: requestID) { req in
                    // 更新请求状态为已停止
                    req.runtime.status = .stopped
                    // 清除错误信息
                    req.runtime.error = nil
                    // 清除速度信息
                    req.runtime.speed = ""
                    // 重置进度
                    req.runtime.percent = 0
                }
            }
    }

    /// 恢复下载请求
    /// - Parameter requestID: 要恢复的请求ID
    func resume(requestID: Request.ID) {
        // 查找指定ID的请求
        let request = requests.first(where: { $0.id == requestID })
        // 如果请求不存在，则返回
        guard let request else { return }
        if isCompleted(for: request) { return }

        // 更新请求状态为待处理
        alter(reqID: requestID) { req in
            req.runtime.status = .pending
            req.runtime.error = nil
            req.runtime.speed = ""
            req.runtime.percent = 0
        }
        // 在全局队列异步执行下载
        DispatchQueue.global().async {
            DiggerManager.shared.download(with: request.url)
                // 监听下载速度
                .speed { speedInput in
                    let speed = self.byteFormat(bytes: speedInput)
                    self.report(speed: speed, reqId: requestID)
                }
                // 监听下载进度
                .progress { progress in
                    self.report(progress: progress, reqId: requestID)
                }
                // 监听下载完成
                .completion { output in
                    DispatchQueue.global().async {
                        // 处理下载结果
                        switch output {
                        case let .success(url):
                            // 报告正在验证
                            self.reportValidating(reqId: requestID)
                            // 处理下载完成的文件
                            self.finalize(request: request, url: url)
                        case let .failure(error):
                            // 报告下载错误
                            self.report(error: error, reqId: requestID)
                        }
                    }
                }
        }
    }

    /// 处理下载完成的文件
    /// - Parameters:
    ///   - request: 下载请求
    ///   - url: 下载文件的临时URL
    func finalize(request: Request, url: URL) {
        // 目标文件位置
        let targetLocation = request.targetLocation

        do {
            // 获取请求中的MD5和文件的实际MD5
            let md5 = request.md5
            let fileMD5 = md5File(url: url)
            // 验证MD5是否匹配
            guard md5.lowercased() == fileMD5?.lowercased() else {
                // MD5不匹配，报告错误
                report(error: NSError(domain: "MD5", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: NSLocalizedString("MD5 mismatch", comment: ""),
                ]), reqId: request.id)
                return
            }

            // 删除已存在的目标文件（如果有）
            // 发生错误，删除目标文件
            try? FileManager.default.removeItem(at: targetLocation)
            // 创建目标文件所在的目录（如果不存在）
            try? FileManager.default.createDirectory(
                at: targetLocation.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            // 移动下载的文件到目标位置
            try FileManager.default.moveItem(at: url, to: targetLocation)
            // 编码元数据
            let data = try JSONEncoder().encode(request.metadata)
            // 解码为字典
            let object = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]

            // 打印元数据写入路径
            print("[*] 发送元数据到 \(targetLocation.path)")
            // 创建项目对象
            let item = StoreResponse.Item(
                url: request.url,
                md5: request.md5,
                signatures: request.signatures,
                metadata: object
            )
            // 创建签名客户端
            let signatureClient = SignatureClient(fileManager: .default, filePath: targetLocation.path)
            // 添加元数据
            try signatureClient.appendMetadata(item: item, email: request.account.email)
            // 添加签名
            try signatureClient.appendSignature(item: item)

            reportSuccess(reqId: request.id)
        } catch {
            try? FileManager.default.removeItem(at: targetLocation)
            // 报告错误
            report(error: error, reqId: request.id)
        }
    }

    /// 删除下载请求
    /// - Parameter request: 要删除的下载请求
    func delete(request: Request) {
        // 在主线程异步执行删除操作
        DispatchQueue.main.async { [self] in
            // 取消下载任务
              DiggerManager.shared.cancelTask(for: request.url)
            // 移除下载种子
              DiggerManager.shared.removeDigeerSeed(for: request.url)
            // 从请求数组中移除
              requests.removeAll { $0.id == request.id }
            // 删除目标文件
              try? FileManager.default.removeItem(at: request.targetLocation)
        }
    }

    /// 恢复所有下载请求
    func resumeAll() {
        // 遍历所有请求并恢复
        for req in requests {
            resume(requestID: req.id)
        }
    }

    /// 暂停所有下载请求
    func suspendAll() {
        // 停止所有下载任务
        DiggerManager.shared.stopAllTasks()
    }

    /// 移除所有下载请求
    func removeAll() {
        let copy = requests
        // 遍历所有请求并删除
        for req in requests {
            delete(request: req)
        }
    }

    /// 根据存档查找下载请求
    /// - Parameter archive: iTunes存档对象
    /// - Returns: 找到的下载请求，如果没有找到则返回nil
    /// 根据存档查找下载请求
    /// - Parameter archive: iTunes存档对象
    /// - Returns: 找到的下载请求，如果没有找到则返回nil
    func downloadRequest(forArchive archive: iTunesResponse.iTunesArchive) -> Request? {
        // 遍历所有请求查找匹配的存档
        for req in requests {
            if req.package == archive {
                return req
            }
        }
        return nil
    }

    /// 报告下载成功
    /// - Parameter reqId: 请求ID
    private func reportSuccess(reqId: Request.ID) {
        alter(reqID: reqId) { req in
            req.runtime.status = .completed
            req.runtime.percent = 1
        }
    }

    /// 报告正在验证
    /// - Parameter reqId: 请求ID
    private func reportValidating(reqId: Request.ID) {
        alter(reqID: reqId) { req in
            req.runtime.status = .validating
        }
    }

    /// 报告错误
    /// - Parameters:
    ///   - error: 错误信息
    ///   - reqId: 请求ID
    private func report(error: Error, reqId: Request.ID) {
        alter(reqID: reqId) { req in
            req.runtime.status = .error
            req.runtime.error = error.localizedDescription
        }
    }

    /// 报告下载速度
    /// - Parameters:
    ///   - speed: 下载速度字符串
    ///   - reqId: 请求ID
    private func report(speed: String, reqId: Request.ID) {
        alter(reqID: reqId) { req in
            req.runtime.speed = speed
        }
    }

    /// 报告下载进度
    /// - Parameters:
    ///   - progress: 下载进度(0-1)
    ///   - reqId: 请求ID
    private func report(progress: Double, reqId: Request.ID) {
        alter(reqID: reqId) { req in
            req.runtime.percent = progress
            if progress > 0 && req.runtime.status != .downloading {
                req.runtime.status = .downloading
            }
        }
    }

    /// 修改请求属性
    /// - Parameters:
    ///   - reqId: 请求ID
    ///   - transform: 转换闭包，用于修改请求属性
    private func alter(reqID: Request.ID, transform: (inout Request) -> Void) {
        if let index = requests.firstIndex(where: { $0.id == reqID }) {
            var request = requests[index]
            transform(&request)
            requests[index] = request
        }
    }

    /// 计算文件的MD5哈希值
    /// - Parameter url: 文件URL
    /// - Returns: MD5哈希字符串，如果计算失败则返回nil
    private func md5File(url: URL) -> String? {
        do {
            let data = try Data(contentsOf: url)
            return data.md5
        } catch {
            return nil
        }
    }
}

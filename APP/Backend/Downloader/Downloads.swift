import AnyCodable  // 支持任何类型的Codable
import ApplePackage  // Apple包处理库
import Combine       // 响应式编程框架
import Digger        // 下载管理器库
import Foundation    // 基础框架

/// 字节格式化器，用于格式化文件大小显示
private let byteFormatter: ByteCountFormatter = {
    let formatter = ByteCountFormatter()
    formatter.allowedUnits = [.useAll]
    formatter.countStyle = .file
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
        for req in copy where !isCompleted(for: req) {
            alter(reqID: req.id) { req in
                req.runtime.status = .stopped
            }
        }

        DiggerManager.shared.maxConcurrentTasksCount = 4
        DiggerManager.shared.timeout = 15
    }

    func isCompleted(for request: Request) -> Bool {
        if FileManager.default.fileExists(atPath: request.targetLocation.path) {
            reportSuccess(reqId: request.id)
            return true
        }
        return false
    }

    @discardableResult
    func add(request: Request) -> Request.ID {
        if Thread.isMainThread {
            requests.insert(request, at: 0)
            return request.id
        } else {
            DispatchQueue.main.asyncAndWait {
                self.requests.insert(request, at: 0)
            }
            return request.id
        }
    }

    func byteFormat(bytes: Int64) -> String {
        if bytes > 0 {
            return byteFormatter.string(fromByteCount: bytes)
        }
        return ""
    }

    func suspend(requestID: Request.ID) {
        let request = requests.first(where: { $0.id == requestID })
        guard let request else { return }
        if isCompleted(for: request) { return }
        DiggerManager.shared.stopTask(for: request.url)
        // wait for callback to trigger
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            self.alter(reqID: requestID) { req in
                req.runtime.status = .stopped
                req.runtime.error = nil
                req.runtime.speed = ""
                req.runtime.percent = 0
            }
        }
    }

    func resume(requestID: Request.ID) {
        let request = requests.first(where: { $0.id == requestID })
        guard let request else { return }
        if isCompleted(for: request) { return }

        alter(reqID: requestID) { req in
            req.runtime.status = .pending
            req.runtime.error = nil
            req.runtime.speed = ""
            req.runtime.percent = 0
        }
        DispatchQueue.global().async {
            DiggerManager.shared.download(with: request.url)
                .speed { speedInput in
                    let speed = self.byteFormat(bytes: speedInput)
                    self.report(speed: speed, reqId: requestID)
                }
                .progress { progress in
                    self.report(progress: progress, reqId: requestID)
                }
                .completion { output in
                    DispatchQueue.global().async {
                        switch output {
                        case let .success(url):
                            self.reportValidating(reqId: requestID)
                            self.finalize(request: request, url: url)
                        case let .failure(error):
                            self.report(error: error, reqId: requestID)
                        }
                    }
                }
        }
    }

    func finalize(request: Request, url: URL) {
        let targetLocation = request.targetLocation

        do {
            let md5 = request.md5
            let fileMD5 = md5File(url: url)
            guard md5.lowercased() == fileMD5?.lowercased() else {
                report(error: NSError(domain: "MD5", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: NSLocalizedString("MD5 mismatch", comment: ""),
                ]), reqId: request.id)
                return
            }

            try? FileManager.default.removeItem(at: targetLocation)
            try? FileManager.default.createDirectory(
                at: targetLocation.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try FileManager.default.moveItem(at: url, to: targetLocation)
            let data = try JSONEncoder().encode(request.metadata)
            let object = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] ?? [:]

            print("[*] sending metadata into \(targetLocation.path)")
            let item = StoreResponse.Item(
                url: request.url,
                md5: request.md5,
                signatures: request.signatures,
                metadata: object
            )
            let signatureClient = SignatureClient(fileManager: .default, filePath: targetLocation.path)
            try signatureClient.appendMetadata(item: item, email: request.account.email)
            try signatureClient.appendSignature(item: item)

            reportSuccess(reqId: request.id)
        } catch {
            try? FileManager.default.removeItem(at: targetLocation)
            report(error: error, reqId: request.id)
        }
    }

    func delete(request: Request) {
        DispatchQueue.main.async { [self] in
            DiggerManager.shared.cancelTask(for: request.url)
            DiggerManager.shared.removeDigeerSeed(for: request.url)
            requests.removeAll { $0.id == request.id }
            try? FileManager.default.removeItem(at: request.targetLocation)
        }
    }

    func resumeAll() {
        for req in requests {
            resume(requestID: req.id)
        }
    }

    func suspendAll() {
        DiggerManager.shared.stopAllTasks()
    }

    func removeAll() {
        let copy = requests
        for req in copy {
            delete(request: req)
        }
    }

    func downloadRequest(forArchive archive: iTunesResponse.iTunesArchive) -> Request? {
        for req in requests {
            if req.package == archive {
                return req
            }
        }
        return nil
    }
}

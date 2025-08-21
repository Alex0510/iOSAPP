import ApplePackage
import Combine
import CommonCrypto
import Foundation


// 下载管理器主类
class Downloads: ObservableObject {
    static let shared = Downloads()
    
    @Published var requests: [Request] = []
    
    private var downloadTasks: [UUID: URLSessionDownloadTask] = [:]
    private var urlSession: URLSession
    private let persistenceKey = "downloads_requests"
    
    private init() {
        let config = URLSessionConfiguration.default
        self.urlSession = URLSession(configuration: config)
        loadRequests()
    }
    
    private func loadRequests() {
        if let data = UserDefaults.standard.data(forKey: persistenceKey),
           let decoded = try? JSONDecoder().decode([Request].self, from: data) {
            self.requests = decoded
        }
    }
    
    private func saveRequests() {
        if let encoded = try? JSONEncoder().encode(requests) {
            UserDefaults.standard.set(encoded, forKey: persistenceKey)
        }
    }
    
    // 添加下载请求
    func add(_ request: Request) {
        DispatchQueue.main.async {
            self.requests.append(request)
            self.saveRequests()
        }
    }
    
    // 开始下载
    func start(_ requestId: UUID) {
        guard let index = requests.firstIndex(where: { $0.id == requestId }) else { return }
        
        alter(requestId) { request in
            request.runtime.status = .downloading
            request.runtime.error = nil
        }
        
        let request = requests[index]
        let downloadTask = urlSession.downloadTask(with: request.url) { [weak self] localURL, response, error in
            self?.handleDownloadCompletion(requestId: requestId, localURL: localURL, response: response, error: error)
        }
        
        downloadTasks[requestId] = downloadTask
        downloadTask.resume()
    }
    
    // 暂停下载
    func suspend(_ requestId: UUID) {
        downloadTasks[requestId]?.suspend()
        alter(requestId) { request in
            request.runtime.status = .stopped
        }
    }
    
    // 恢复下载
    func resume(_ requestId: UUID) {
        downloadTasks[requestId]?.resume()
        alter(requestId) { request in
            request.runtime.status = .downloading
        }
    }
    
    // 删除下载
    func remove(_ requestId: UUID) {
        downloadTasks[requestId]?.cancel()
        downloadTasks.removeValue(forKey: requestId)
        
        DispatchQueue.main.async {
            self.requests.removeAll { $0.id == requestId }
            self.saveRequests()
        }
    }
    
    // 根据archive查找下载请求
    func downloadRequest(forArchive archive: iTunesResponse.iTunesArchive) -> Request? {
        return requests.first { $0.package.bundleIdentifier == archive.bundleIdentifier }
    }
    
    // 检查下载是否已完成
    func isCompleted(for request: Request) -> Bool {
        return request.runtime.status == .completed
    }
    
    // 删除下载请求（别名方法）
    func delete(request: Request) {
        remove(request.id)
    }
    
    
    // 修改请求状态
    private func alter(_ requestId: UUID, _ modifier: @escaping (inout Request) -> Void) {
        DispatchQueue.main.async {
            if let index = self.requests.firstIndex(where: { $0.id == requestId }) {
                modifier(&self.requests[index])
                self.saveRequests()
            }
        }
    }
    
    // 处理下载完成
    private func handleDownloadCompletion(requestId: UUID, localURL: URL?, response: URLResponse?, error: Error?) {
        if let error = error {
            report(error: error, reqId: requestId)
            return
        }
        
        guard let localURL = localURL else {
            report(error: NSError(domain: "DownloadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No local URL"]), reqId: requestId)
            return
        }
        
        // 验证MD5
        guard let request = requests.first(where: { $0.id == requestId }) else { return }
        
        if verifyMD5(fileURL: localURL, expectedMD5: request.md5) {
            reportSuccess(reqId: requestId, localPath: localURL)
        } else {
            report(error: NSError(domain: "DownloadError", code: -2, userInfo: [NSLocalizedDescriptionKey: "MD5 verification failed"]), reqId: requestId)
        }
    }
    
    // 报告错误
    private func report(error: Error, reqId: UUID) {
        alter(reqId) { request in
            request.runtime.status = .stopped
            request.runtime.error = error.localizedDescription
        }
    }
    
    // 报告成功
    private func reportSuccess(reqId: UUID, localPath: URL) {
        alter(reqId) { request in
            request.runtime.status = .completed
            request.runtime.localPath = localPath.path
            request.runtime.percent = 1.0
        }
    }
    
    // MD5验证
    private func verifyMD5(fileURL: URL, expectedMD5: String) -> Bool {
        guard let data = try? Data(contentsOf: fileURL) else { return false }
        let calculatedMD5 = data.md5
        return calculatedMD5.lowercased() == expectedMD5.lowercased()
    }
}

// Data扩展，用于MD5计算
extension Data {
    var md5: String {
        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        _ = self.withUnsafeBytes { bytes in
            CC_MD5(bytes.bindMemory(to: UInt8.self).baseAddress, CC_LONG(self.count), &digest)
        }
        
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

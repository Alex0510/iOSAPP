import Foundation  // 基础框架

/// Downloads类的扩展，提供下载状态报告功能
extension Downloads {
    /// 根据请求ID执行变更操作并更新请求
    func alter(reqID: Request.ID, _ callback: @escaping (inout Request) -> Void) {
        DispatchQueue.main.async { [self] in
            guard let index = requests.firstIndex(where: { $0.id == reqID }) else { return }
            var req = requests[index]
            let deduplicate = req
            callback(&req)
            guard deduplicate != req else { return }
            requests[index] = req
        }
    }

    /// 报告下载请求正在验证中
    func reportValidating(reqId: Request.ID) {
        alter(reqID: reqId) { req in
            req.runtime.status = .verifying
        }
    }

    /// 报告下载请求成功完成
    func reportSuccess(reqId: Request.ID) {
        alter(reqID: reqId) { req in
            req.runtime.status = .completed
            req.runtime.percent = 1
            req.runtime.error = nil
        }
    }

    /// 报告下载错误
    func report(error: Error?, reqId: Request.ID) {
        print(Thread.callStackSymbols.joined(separator: "\n"))
        let error = error ?? NSError(domain: "DownloadManager", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "Unknown error",
        ])
        alter(reqID: reqId) { req in
            req.runtime.error = error.localizedDescription
            req.runtime.status = .stopped
        }
    }

    /// 报告下载进度
    func report(progress: Progress, reqId: Request.ID) {
        alter(reqID: reqId) { req in
            req.runtime.percent = progress.fractionCompleted
            req.runtime.status = .downloading
            req.runtime.error = nil
        }
    }

    func report(speed: String, reqId: Request.ID) {
        alter(reqID: reqId) { req in
            req.runtime.speed = speed
            req.runtime.status = .downloading
            req.runtime.error = nil
        }
    }
}

import Foundation
import Combine

/// Downloads类的增强扩展，集成DownloadManager.swift的优秀特性
extension Downloads {
    
    /// 增强的下载进度监控
    func enhancedDownload(request: Request) {
        guard let url = URL(string: request.downloadURL) else {
            report(error: NSError(domain: "DownloadManager", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "无效的下载URL"
            ]), reqId: request.id)
            return
        }
        
        // 报告开始下载
        alter(reqID: request.id) { req in
            req.runtime.status = .downloading
            req.runtime.percent = 0.0
            req.runtime.error = nil
        }
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 300.0
        let session = URLSession(configuration: configuration)
        
        let downloadTask = session.downloadTask(with: url) { [weak self] (fileURL, response, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // 增强的错误处理
                if let error = error {
                    let enhancedError = self.enhanceError(error: error, request: request)
                    self.report(error: enhancedError, reqId: request.id)
                    return
                }
                
                guard let fileURL = fileURL, let httpResponse = response as? HTTPURLResponse else {
                    let error = NSError(domain: "DownloadManager", code: -2, userInfo: [
                        NSLocalizedDescriptionKey: "下载失败，无法获取文件"
                    ])
                    self.report(error: error, reqId: request.id)
                    return
                }
                
                // HTTP状态码检查
                if httpResponse.statusCode != 200 {
                    let error = NSError(domain: "DownloadManager", code: httpResponse.statusCode, userInfo: [
                        NSLocalizedDescriptionKey: "服务器错误: HTTP \(httpResponse.statusCode)"
                    ])
                    self.report(error: error, reqId: request.id)
                    return
                }
                
                // 文件处理和验证
                self.processDownloadedFile(fileURL: fileURL, request: request)
            }
        }
        
        // 增强的进度监控
        let progressObservation = downloadTask.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            DispatchQueue.main.async {
                self?.report(progress: progress, reqId: request.id)
                
                // 计算下载速度
                let speed = self?.calculateDownloadSpeed(progress: progress, request: request) ?? "未知"
                self?.report(speed: speed, reqId: request.id)
            }
        }
        
        // 存储观察者以便后续清理
        alter(reqID: request.id) { req in
            req.runtime.progressObservation = progressObservation
        }
        
        downloadTask.resume()
    }
    
    /// 增强的错误处理
    private func enhanceError(error: Error, request: Request) -> Error {
        let nsError = error as NSError
        
        // 根据错误类型提供更详细的错误信息
        switch nsError.code {
        case NSURLErrorTimedOut:
            return NSError(domain: "DownloadManager", code: nsError.code, userInfo: [
                NSLocalizedDescriptionKey: "下载超时，请检查网络连接",
                NSLocalizedFailureReasonErrorKey: "网络连接超时"
            ])
        case NSURLErrorNotConnectedToInternet:
            return NSError(domain: "DownloadManager", code: nsError.code, userInfo: [
                NSLocalizedDescriptionKey: "无网络连接，请检查网络设置",
                NSLocalizedFailureReasonErrorKey: "网络不可用"
            ])
        case NSURLErrorCannotFindHost:
            return NSError(domain: "DownloadManager", code: nsError.code, userInfo: [
                NSLocalizedDescriptionKey: "无法连接到服务器",
                NSLocalizedFailureReasonErrorKey: "服务器地址无效"
            ])
        case NSURLErrorCancelled:
            return NSError(domain: "DownloadManager", code: nsError.code, userInfo: [
                NSLocalizedDescriptionKey: "下载已取消",
                NSLocalizedFailureReasonErrorKey: "用户取消下载"
            ])
        default:
            return NSError(domain: "DownloadManager", code: nsError.code, userInfo: [
                NSLocalizedDescriptionKey: error.localizedDescription,
                NSLocalizedFailureReasonErrorKey: "下载过程中发生错误"
            ])
        }
    }
    
    /// 处理下载完成的文件
    private func processDownloadedFile(fileURL: URL, request: Request) {
        // 报告验证状态
        reportValidating(reqId: request.id)
        
        // 创建目标目录
        let documentsURL = FileManager.default.temporaryDirectory
        let destinationURL = documentsURL.appendingPathComponent(request.package.bundleIdentifier + ".ipa")
        
        // 删除已存在的文件
        try? FileManager.default.removeItem(at: destinationURL)
        
        do {
            // 移动文件
            try FileManager.default.moveItem(at: fileURL, to: destinationURL)
            
            // MD5验证（如果提供）
            if !request.md5.isEmpty {
                let fileMD5 = calculateMD5(for: destinationURL)
                if fileMD5.lowercased() != request.md5.lowercased() {
                    let error = NSError(domain: "DownloadManager", code: -3, userInfo: [
                        NSLocalizedDescriptionKey: "文件完整性验证失败",
                        NSLocalizedFailureReasonErrorKey: "MD5校验不匹配"
                    ])
                    report(error: error, reqId: request.id)
                    return
                }
            }
            
            // 更新请求的本地路径
            alter(reqID: request.id) { req in
                req.runtime.localPath = destinationURL.path
            }
            
            // 报告成功
            reportSuccess(reqId: request.id)
            
        } catch {
            let enhancedError = NSError(domain: "DownloadManager", code: -4, userInfo: [
                NSLocalizedDescriptionKey: "无法保存文件: \(error.localizedDescription)",
                NSLocalizedFailureReasonErrorKey: "文件系统错误"
            ])
            report(error: enhancedError, reqId: request.id)
        }
    }
    
    /// 计算下载速度
    private func calculateDownloadSpeed(progress: Progress, request: Request) -> String {
        let currentTime = Date().timeIntervalSince1970
        let bytesReceived = Int64(progress.fractionCompleted * Double(progress.totalUnitCount))
        
        // 获取上次记录的时间和字节数
        guard let lastTime = getLastSpeedCheckTime(for: request.id),
              let lastBytes = getLastSpeedCheckBytes(for: request.id) else {
            // 首次记录
            setLastSpeedCheck(for: request.id, time: currentTime, bytes: bytesReceived)
            return "计算中..."
        }
        
        let timeDiff = currentTime - lastTime
        let bytesDiff = bytesReceived - lastBytes
        
        guard timeDiff > 0 else { return "计算中..." }
        
        let speed = Double(bytesDiff) / timeDiff // bytes per second
        
        // 更新记录
        setLastSpeedCheck(for: request.id, time: currentTime, bytes: bytesReceived)
        
        return formatSpeed(speed)
    }
    
    /// 格式化速度显示
    private func formatSpeed(_ bytesPerSecond: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .binary
        return "\(formatter.string(fromByteCount: Int64(bytesPerSecond)))/s"
    }
    
    /// MD5计算
    private func calculateMD5(for url: URL) -> String {
        guard let data = try? Data(contentsOf: url) else { return "" }
        return data.md5
    }
    
    // MARK: - 速度计算辅助方法
    private func getLastSpeedCheckTime(for requestId: Request.ID) -> TimeInterval? {
        return UserDefaults.standard.object(forKey: "speed_time_\(requestId)") as? TimeInterval
    }
    
    private func getLastSpeedCheckBytes(for requestId: Request.ID) -> Int64? {
        let bytes = UserDefaults.standard.object(forKey: "speed_bytes_\(requestId)") as? Int64
        return bytes == 0 ? nil : bytes
    }
    
    private func setLastSpeedCheck(for requestId: Request.ID, time: TimeInterval, bytes: Int64) {
        UserDefaults.standard.set(time, forKey: "speed_time_\(requestId)")
        UserDefaults.standard.set(bytes, forKey: "speed_bytes_\(requestId)")
    }
}

// MARK: - Data扩展，用于MD5计算
extension Data {
    var md5: String {
        let hash = self.withUnsafeBytes { bytes in
            return CC_MD5(bytes.bindMemory(to: UInt8.self).baseAddress, CC_LONG(self.count), nil)
        }
        return (0..<Int(CC_MD5_DIGEST_LENGTH)).map { String(format: "%02hhx", hash![$0]) }.joined()
    }
}

// 需要导入CommonCrypto
import CommonCrypto
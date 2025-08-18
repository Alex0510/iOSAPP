//
//  IPATool.swift
//  MuffinStoreJailed++
//
//  Created by pxx917144686 on 2025.08.18
//  Optimized for jailbroken devices — No Apple ID required.
//

import Foundation
import Zip

// MARK: - 响应模型
struct AppVersionInfo: Codable {
    let bundle_version: String
    let external_identifier: String
}

struct VersionResponse: Codable {
    let data: [AppVersionInfo]
}

// MARK: - 免登录 IPATool
class IPATool {
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.httpAdditionalHeaders = [
            "User-Agent": "MuffinStoreJailed++/1.0 (iPhone; iOS 15.0)"
        ]
        return URLSession(configuration: config)
    }()

    // 兼容原接口，无需真实账号
    init(appleId: String = "", password: String = "") {
        // 无需任何操作
    }

    // 模拟认证成功（直接返回 true）
    func authenticate() async -> Bool {
        print("✅ 免登录模式：跳过 Apple ID 认证")
        return true
    }

    // 从 bilin API 获取某 App 的所有历史版本 ID 列表
    func getVersionIDList(appId: String) async throws -> [String] {
        guard let url = URL(string: "https://apis.bilin.eu.org/history/\(appId)") else {
            throw NSError(domain: "Network", code: 1001, userInfo: [NSLocalizedDescriptionKey: "无效的应用 ID"])
        }

        print("📡 正在获取版本列表: \(url.absoluteString)")

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "Network", code: 1002, userInfo: [NSLocalizedDescriptionKey: "服务器返回错误状态"])
        }

        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(VersionResponse.self, from: data)
            if result.data.isEmpty {
                throw NSError(domain: "Data", code: 1003, userInfo: [NSLocalizedDescriptionKey: "未找到该应用的历史版本"])
            }
            let versionIds = result.data.map { $0.external_identifier }
            print("📦 获取到 \(versionIds.count) 个版本: \(versionIds)")
            return versionIds
        } catch {
            print("❌ 解析版本列表失败: \(error.localizedDescription)")
            throw error
        }
    }

    // 下载指定版本的 IPA 并解压，返回 Payload 所在目录路径
    func downloadIPAForVersion(appId: String, appVerId: String) async throws -> String {
        // 构造下载链接
        let downloadURLString = "https://download.bilin.eu.org/ipa/\(appId)/\(appVerId).ipa"
        guard let downloadURL = URL(string: downloadURLString) else {
            throw NSError(domain: "Download", code: 2001, userInfo: [NSLocalizedDescriptionKey: "无法构建下载链接"])
        }

        let fileManager = FileManager.default
        let tempDir = fileManager.temporaryDirectory

        // 1. 下载 IPA
        let ipaFileURL = tempDir.appendingPathComponent("\(appId)_\(appVerId).ipa")
        print("⬇️ 开始下载 IPA: \(downloadURL.absoluteString)")

        do {
            let (data, _) = try await session.data(from: downloadURL)
            try data.write(to: ipaFileURL, options: .atomic)
            print("✅ IPA 已下载至: \(ipaFileURL.path)")
        } catch {
            throw NSError(domain: "Download", code: 2002, userInfo: [
                NSLocalizedDescriptionKey: "下载失败，请检查网络或链接是否有效",
                "error": error.localizedDescription
            ])
        }

        // 2. 解压 IPA
        let unzipDir = tempDir.appendingPathComponent("unzipped_\(appId)_\(appVerId)", isDirectory: true)
        if fileManager.fileExists(atPath: unzipDir.path) {
            try fileManager.removeItem(at: unzipDir)
        }

        do {
            try Zip.unzipFile(ipaFileURL, destination: unzipDir, overwrite: true, password: nil, progress: nil)
            print("📂 IPA 已解压至: \(unzipDir.path)")
        } catch {
            throw NSError(domain: "Unzip", code: 2003, userInfo: [
                NSLocalizedDescriptionKey: "解压失败",
                "error": error.localizedDescription
            ])
        }

        // 3. 写入伪造元数据
        try await writeFakeMetadata(to: unzipDir, appId: appId, versionId: appVerId)

        // 4. 返回解压目录路径
        return unzipDir.path
    }

    // 生成伪造的 iTunesMetadata.plist 并创建 SC_Info 目录
    private func writeFakeMetadata(to unzipDir: URL, appId: String, versionId: String) async throws {
        let metadataURL = unzipDir.appendingPathComponent("iTunesMetadata.plist")
        let fakeData: [String: Any] = [
            "apple-id": "0",
            "userName": "anonymous@local",
            "accountName": "Anonymous",
            "partition": "0",
            "purchaseDate": ISO8601DateFormatter().string(from: Date()),
            "bvrs": [appId: versionId],
            "kind": "software",
            "softwareIcon512URL": "",
            "softwareVersionBundleId": appId
        ]

        (fakeData as NSDictionary).write(to: metadataURL, atomically: true)
        print("📄 已生成伪造的 iTunesMetadata.plist")

        // 检查 Payload 目录
        let payloadURL = unzipDir.appendingPathComponent("Payload")
        guard FileManager.default.fileExists(atPath: payloadURL.path) else {
            print("⚠️ 错误：Payload 目录不存在！路径: \(payloadURL.path)")
            return
        }

        // 遍历 Payload 查找 .app 文件夹
        let contents = try FileManager.default.contentsOfDirectory(
            at: payloadURL,
            includingPropertiesForKeys: nil as [URLResourceKey]?
        )

        for entry in contents {
            if entry.pathExtension == "app" {
                let scInfoDir = entry.appendingPathComponent("SC_Info")
                try FileManager.default.createDirectory(at: scInfoDir, withIntermediateDirectories: true)
                print("📁 已创建空 SC_Info 目录: \(scInfoDir.path)")
                break
            }
        }
    }
}

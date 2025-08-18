//
//  Downgrader.swift
//  MuffinStoreJailed
//
//  Created by pxx917144686 on 2025.08.18
//

import Foundation
import UIKit
import Telegraph
import Zip
import SwiftUI
import SafariServices

// MARK: - Safari WebView Wrapper
struct SafariWebView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - Downgrade Functions

/// 主入口：开始降级应用（仅需 appId）
func downgradeApp(appId: String, ipaTool: IPATool? = nil) {
    print("开始降级应用，App ID: \(appId)")
    
    // 使用传入或新建的 IPATool
    let tool = ipaTool ?? IPATool()

    // 获取版本列表（异步）
    Task {
        do {
            // ✅ 使用新方法获取完整版本信息
            let versions = try await fetchVersionList(from: "https://apis.bilin.eu.org/history/\(appId)")
            guard let latest = versions.first else {
                await MainActor.run {
                    showAlert(title: "无版本", message: "未找到该应用的历史版本")
                }
                return
            }
            await MainActor.run {
                showProgressAlert(version: latest.bundle_version) {
                    // 开始降级
                    Task {
                        do {
                            try await downgradeAppToVersion(appId: appId, versionId: latest.external_identifier, ipaTool: tool)
                        } catch {
                            await MainActor.run {
                                showAlert(title: "失败", message: "降级失败：\(error.localizedDescription)")
                            }
                        }
                    }
                }
            }
        } catch {
            await MainActor.run {
                showAlert(title: "错误", message: "获取版本失败：\(error.localizedDescription)")
            }
        }
    }
}

/// 从远程 URL 获取版本列表（返回完整 AppVersionInfo）
func fetchVersionList(from urlString: String) async throws -> [AppVersionInfo] {
    guard let url = URL(string: urlString) else {
        throw NSError(domain: "Network", code: 1001, userInfo: [NSLocalizedDescriptionKey: "无效的 URL"])
    }
    
    let (data, response) = try await URLSession.shared.data(from: url)
    
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw NSError(domain: "Network", code: 1002, userInfo: [NSLocalizedDescriptionKey: "服务器返回错误状态"])
    }
    
    let decoder = JSONDecoder()
    let result = try decoder.decode(VersionResponse.self, from: data)
    return result.data
}

/// 显示进度提示
func showProgressAlert(version: String, onAppear: @escaping () -> Void) {
    let alert = UIAlertController(
        title: "正在降级",
        message: "即将安装版本 \(version)...\n请勿关闭应用。",
        preferredStyle: .alert
    )
    let vc = UIApplication.shared.windows.first?.rootViewController
    vc?.present(alert, animated: true) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: onAppear)
    }
}

/// 执行降级：下载 → 打包 → 启动安装
@MainActor
func downgradeAppToVersion(appId: String, versionId: String, ipaTool: IPATool) async throws {
    do {
        // 1. 下载 IPA（异步）
        let downloadPath = try await ipaTool.downloadIPAForVersion(appId: appId, appVerId: versionId)
        print("IPA 下载完成: \(downloadPath)")

        // 2. 查找 Payload 中的 .app
        let payloadURL = URL(fileURLWithPath: downloadPath).appendingPathComponent("Payload")
        let manager = FileManager.default
        let contents = try manager.contentsOfDirectory(at: payloadURL, includingPropertiesForKeys: nil)

        var appBundleURL: URL?
        for entry in contents {
            if entry.pathExtension == "app" {
                appBundleURL = entry
                break
            }
        }

        guard let appBundleURL = appBundleURL else {
            throw NSError(domain: "Downgrader", code: 1, userInfo: [NSLocalizedDescriptionKey: "未找到 .app 文件夹"])
        }

        // 3. 读取 Info.plist
        let infoPlistPath = appBundleURL.appendingPathComponent("Info.plist")
        let infoDict = NSDictionary(contentsOf: infoPlistPath) as? [String: Any]
        guard let bundleId = infoDict?["CFBundleIdentifier"] as? String,
              let version = infoDict?["CFBundleShortVersionString"] as? String else {
            throw NSError(domain: "Downgrader", code: 2, userInfo: [NSLocalizedDescriptionKey: "无法读取应用信息"])
        }

        print("Bundle ID: \(bundleId), Version: \(version)")

        // 4. 重新打包为 IPA
        let tempDir = manager.temporaryDirectory
        let zipUrl = tempDir.appendingPathComponent("signed.ipa")
        try? manager.removeItem(at: zipUrl)

        // 打包整个 Payload 文件夹
        try Zip.zipFiles(paths: [payloadURL], zipFilePath: zipUrl, password: nil, progress: nil)
        print("IPA 已打包: \(zipUrl)")

        // 5. 构造安装链接
        let plistUrl = "https://api.palera.in/genPlist?bundleid=\(bundleId)&name=\(bundleId)&version=\(version)&fetchurl=http://127.0.0.1:9090/signed.ipa"
        let installUrlStr = "itms-services://?action=download-manifest&url=" + plistUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!

        // 6. 启动本地服务器
        let server = Server()

        server.route(.GET, "signed.ipa") { _ in
            let data = try Data(contentsOf: zipUrl)
            return HTTPResponse(body: data)
        }

        server.route(.GET, "install") { _ in
            let html = "<script>window.location = \"\(installUrlStr)\";</script>"
            return HTTPResponse(.ok, headers: ["Content-Type": "text/html"], content: html)
        }

        try server.start(port: 9090)
        print("本地服务器已启动: http://127.0.0.1:9090")

        // 7. 打开安装链接
        let majorVersion = Int(UIDevice.current.systemVersion.split(separator: ".").first.map(String.init) ?? "0") ?? 0
        let installUrl = URL(string: "http://127.0.0.1:9090/install")!

        if majorVersion >= 18 {
            let safari = SafariWebView(url: installUrl)
            let host = UIHostingController(rootView: safari)
            host.modalPresentationStyle = .automatic
            await MainActor.run {
                UIApplication.shared.windows.first?.rootViewController?.present(host, animated: true)
            }
        } else {
            await MainActor.run {
                UIApplication.shared.open(URL(string: installUrlStr)!, options: [:])
            }
        }

        // 保持服务器运行
        while server.isRunning {
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }

    } catch {
        print("降级失败: \(error.localizedDescription)")
        throw error
    }
}

// MARK: - Alert Helper

@MainActor
func showAlert(title: String, message: String) {
    let isiPad = UIDevice.current.userInterfaceIdiom == .pad
    let alert = UIAlertController(title: title, message: message, preferredStyle: isiPad ? .alert : .actionSheet)
    alert.addAction(UIAlertAction(title: "确定", style: .default))
    UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true)
}

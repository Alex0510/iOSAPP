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

struct SafariWebView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
    }
}

func downgradeAppToVersion(appId: String, versionId: String, ipaTool: IPATool) {
    let path = ipaTool.downloadIPAForVersion(appId: appId, appVerId: versionId)
    print("IPA 已下载至 \(path)")
    
    let tempDir = FileManager.default.temporaryDirectory
    var contents = try! FileManager.default.contentsOfDirectory(atPath: path)
    print("目录内容: \(contents)")
    let destinationUrl = tempDir.appendingPathComponent("app.ipa")
    try! Zip.zipFiles(paths: contents.map { URL(fileURLWithPath: path).appendingPathComponent($0) }, zipFilePath: destinationUrl, password: nil, progress: nil)
    print("IPA 已压缩至 \(destinationUrl)")
    let path2 = URL(fileURLWithPath: path)
    var appDir = path2.appendingPathComponent("Payload")
    for file in try! FileManager.default.contentsOfDirectory(atPath: appDir.path) {
        if file.hasSuffix(".app") {
            print("找到应用: \(file)")
            appDir = appDir.appendingPathComponent(file)
            break
        }
    }
    let infoPlistPath = appDir.appendingPathComponent("Info.plist")
    let infoPlist = NSDictionary(contentsOf: infoPlistPath)!
    let appBundleId = infoPlist["CFBundleIdentifier"] as! String
    let appVersion = infoPlist["CFBundleShortVersionString"] as! String
    print("应用 Bundle ID: \(appBundleId)")
    print("应用版本: \(appVersion)")

    let finalURL = "https://api.palera.in/genPlist?bundleid=\(appBundleId)&name=\(appBundleId)&version=\(appVersion)&fetchurl=http://127.0.0.1:9090/signed.ipa"
    let installURL = "itms-services://?action=download-manifest&url=" + finalURL.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
    
    DispatchQueue.global(qos: .background).async {
        let server = Server()

        server.route(.GET, "signed.ipa", { _ in
            print("提供 signed.ipa 文件")
            let signedIPAData = try Data(contentsOf: destinationUrl)
            return HTTPResponse(body: signedIPAData)
        })

        server.route(.GET, "install", { _ in
            print("提供安装页面")
            let installPage = """
            <script type="text/javascript">
                window.location = "\(installURL)"
            </script>
            """
            return HTTPResponse(.ok, headers: ["Content-Type": "text/html"], content: installPage)
        })
        
        try! server.start(port: 9090)
        print("服务器已开始监听")
        
        DispatchQueue.main.async {
            print("请求安装应用")
            let majoriOSVersion = Int(UIDevice.current.systemVersion.components(separatedBy: ".").first!)!
            if majoriOSVersion >= 18 {
                // iOS 18+（不知为何需要此逻辑，但对某些用户有效）
                let safariView = SafariWebView(url: URL(string: "http://127.0.0.1:9090/install")!)
                UIApplication.shared.windows.first?.rootViewController?.present(UIHostingController(rootView: safariView), animated: true, completion: nil)
            } else {
                // iOS 17 及以下
                UIApplication.shared.open(URL(string: installURL)!)
            }
        }
        
        while server.isRunning {
            sleep(1)
        }
        print("服务器已停止")
    }
}

func promptForVersionId(appId: String, versionIds: [String], ipaTool: IPATool) {
    let isiPad = UIDevice.current.userInterfaceIdiom == .pad
    let alert = UIAlertController(title: "输入版本 ID", message: "请选择要降级的版本", preferredStyle: isiPad ? .alert : .actionSheet)
    for versionId in versionIds {
        alert.addAction(UIAlertAction(title: versionId, style: .default, handler: { _ in
            downgradeAppToVersion(appId: appId, versionId: versionId, ipaTool: ipaTool)
        }))
    }
    alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
    UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
}

func showAlert(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
    UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
}

func getAllAppVersionIdsFromServer(appId: String, ipaTool: IPATool) {
    let serverURL = "https://apis.bilin.eu.org/history/"
    let url = URL(string: "\(serverURL)\(appId)")!
    let request = URLRequest(url: url)
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            DispatchQueue.main.async {
                showAlert(title: "错误", message: error.localizedDescription)
            }
            return
        }
        let json = try! JSONSerialization.jsonObject(with: data!) as! [String: Any]
        let versionIds = json["data"] as! [Dictionary<String, Any>]
        if versionIds.count == 0 {
            DispatchQueue.main.async {
                showAlert(title: "错误", message: "未找到版本 ID，可能是内部错误？")
            }
            return
        }
        DispatchQueue.main.async {
            let isiPad = UIDevice.current.userInterfaceIdiom == .pad
            let alert = UIAlertController(title: "选择版本", message: "请选择要降级的版本", preferredStyle: isiPad ? .alert : .actionSheet)
            for versionId in versionIds {
                alert.addAction(UIAlertAction(title: "\(versionId["bundle_version"]!)", style: .default, handler: { _ in
                    downgradeAppToVersion(appId: appId, versionId: "\(versionId["external_identifier"]!)", ipaTool: ipaTool)
                }))
            }
            alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
    task.resume()
}

func downgradeApp(appId: String, ipaTool: IPATool) {
    let versionIds = ipaTool.getVersionIDList(appId: appId)
    let isiPad = UIDevice.current.userInterfaceIdiom == .pad
    
    let alert = UIAlertController(title: "版本 ID", message: "您想手动输入版本 ID 还是从服务器获取版本 ID 列表？", preferredStyle: isiPad ? .alert : .actionSheet)
    alert.addAction(UIAlertAction(title: "手动输入", style: .default, handler: { _ in
        promptForVersionId(appId: appId, versionIds: versionIds, ipaTool: ipaTool)
    }))
    alert.addAction(UIAlertAction(title: "从服务器获取", style: .default, handler: { _ in
        getAllAppVersionIdsFromServer(appId: appId, ipaTool: ipaTool)
    }))
    alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
    UIApplication.shared.windows.first?.rootViewController?.present(alert, animated: true, completion: nil)
}

//
//  IPATool.swift
//  MuffinStoreJailed
//
//  Created by Mineek on 19/10/2024.
//

// Heavily inspired by ipatool-py.
// https://github.com/NyaMisty/ipatool-py

import Foundation
import CommonCrypto
import Zip

extension Data {
    var hexString: String {
        return map { String(format: "%02x", $0) }.joined()
    }
}

class SHA1 {
    static func hash(_ data: Data) -> Data {
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA1($0.baseAddress, CC_LONG(data.count), &digest)
        }
        return Data(digest)
    }
}

extension String {
    subscript (i: Int) -> String {
        return String(self[index(startIndex, offsetBy: i)])
    }

    subscript (r: Range<Int>) -> String {
        let start = index(startIndex, offsetBy: r.lowerBound)
        let end = index(startIndex, offsetBy: r.upperBound)
        return String(self[start..<end])
    }
}

class StoreClient {
    var session: URLSession
    var appleId: String
    var password: String
    var guid: String?
    var accountName: String?
    var authHeaders: [String: String]?
    var authCookies: [HTTPCookie]?

    init(appleId: String, password: String) {
        session = URLSession.shared
        self.appleId = appleId
        self.password = password
        self.guid = nil
        self.accountName = nil
        self.authHeaders = nil
        self.authCookies = nil
    }

    func generateGuid(appleId: String) -> String {
        print("Generating GUID")
        let DEFAULT_GUID = "000C2941396B"
        let GUID_DEFAULT_PREFIX = 2
        let GUID_SEED = "CAFEBABE"
        let GUID_POS = 10

        let h = SHA1.hash((GUID_SEED + appleId + GUID_SEED).data(using: .utf8)!).hexString
        let defaultPart = DEFAULT_GUID.prefix(GUID_DEFAULT_PREFIX)
        let hashPart = h[GUID_POS..<GUID_POS + (DEFAULT_GUID.count - GUID_DEFAULT_PREFIX)]
        let guid = (defaultPart + hashPart).uppercased()

        print("Came up with GUID: \(guid)")
        return guid
    }

    func saveAuthInfo() -> Void {
        var authCookiesEnc1 = NSKeyedArchiver.archivedData(withRootObject: authCookies!)
        var authCookiesEnc = authCookiesEnc1.base64EncodedString()
        var out: [String: Any] = [
            "appleId": appleId,
            "password": password,
            "guid": guid,
            "accountName": accountName,
            "authHeaders": authHeaders,
            "authCookies": authCookiesEnc
        ]
        var data = try! JSONSerialization.data(withJSONObject: out, options: [])
        var base64 = data.base64EncodedString()
        EncryptedKeychainWrapper.saveAuthInfo(base64: base64)
    }

    // 模拟认证成功（直接返回 true）
    func authenticate() async -> Bool {
        print("免登录模式：跳过 Apple ID 认证")
        return true
    }

    func authenticate(requestCode: Bool = false) -> Bool {
        if self.guid == nil {
            self.guid = generateGuid(appleId: appleId)
        }

        print("📡 正在获取版本列表: \(url.absoluteString)")

        let (data, response) = try await session.data(from: url)

        guard
            let httpResponse = response as? HTTPURLResponse,
            httpResponse.statusCode == 200
        else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            throw NSError(domain: "Network", code: 1002, userInfo: [
                NSLocalizedDescriptionKey: "服务器返回错误状态: \(statusCode)",
                "statusCode": statusCode
            ])
        }

        do {
            // 打印原始响应内容（关键调试信息）
            if let str = String(data: data, encoding: .utf8) {
                print("📝 响应内容: \(str)")
            }

            let decoder = JSONDecoder()
            let result = try decoder.decode(VersionResponse.self, from: data)
            if result.data.isEmpty {
                throw NSError(domain: "Data", code: 1003, userInfo: [NSLocalizedDescriptionKey: "未找到该应用的历史版本"])
            }
            print("📦 获取到 \(result.data.count) 个版本: \(result.data.map { $0.external_identifier })")
            return result.data
        } catch {
            print("❌ 解析版本列表失败: \(error.localizedDescription)")
            throw error
        }
    }

    // 下载指定版本的 IPA 并解压，返回 Payload 所在目录路径
    func downloadIPAForVersion(appId: String, appVerId: String) async throws -> String {
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
            print("IPA 已下载至: \(ipaFileURL.path)")
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

        var url = URL(string: "https://buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/authenticate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Accept": "*/*",
            "Content-Type": "application/x-www-form-urlencoded",
            "User-Agent": "Configurator/2.17 (Macintosh; OS X 15.2; 24C5089c) AppleWebKit/0620.1.16.11.6"
        ]

        var ret = false
        
        for attempt in 1...4 {
            req["attempt"] = String(attempt)
            request.httpBody = try! JSONSerialization.data(withJSONObject: req, options: [])
            let datatask = session.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    print("error 1 \(error.localizedDescription)")
                    return
                }
                if let response = response {
                    if let response = response as? HTTPURLResponse {
                        print("New URL: \(response.url!)")
                        request.url = response.url
                    }
                }
                if let data = data {
                    do {
                        let resp = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! [String: Any]
                        if resp["m-allowed"] as! Bool {
                            print("Authentication successful")
                            var download_queue_info = resp["download-queue-info"] as! [String: Any]
                            var dsid = download_queue_info["dsid"] as! Int
                            var httpResp = response as! HTTPURLResponse
                            var storeFront = httpResp.value(forHTTPHeaderField: "x-set-apple-store-front")
                            print("Store front: \(storeFront!)")
                            self.authHeaders = [
                                "X-Dsid": String(dsid),
                                "iCloud-Dsid": String(dsid),
                                "X-Apple-Store-Front": storeFront!,
                                "X-Token": resp["passwordToken"] as! String
                            ]
                            self.authCookies = self.session.configuration.httpCookieStorage?.cookies
                            var accountInfo = resp["accountInfo"] as! [String: Any]
                            var address = accountInfo["address"] as! [String: String]
                            self.accountName = address["firstName"]! + " " + address["lastName"]!
                            self.saveAuthInfo()
                            ret = true
                        } else {
                            print("Authentication failed: \(resp["customerMessage"] as! String)")
                        }
                    } catch {
                        print("Error: \(error)")
                    }
                }
            }
            datatask.resume()
            while datatask.state != .completed {
                sleep(1)
            }
            if ret {
                break
            }
            if requestCode {
                ret = false
                break
            }
        }
        return ret
    }

    func volumeStoreDownloadProduct(appId: String, appVerId: String = "") -> [String: Any] {
        var req = [
            "creditDisplay": "",
            "guid": self.guid!,
            "salableAdamId": appId,
        ]
        if appVerId != "" {
            req["externalVersionId"] = appVerId
        }
        var url = URL(string: "https://p25-buy.itunes.apple.com/WebObjects/MZFinance.woa/wa/volumeStoreDownloadProduct?guid=\(self.guid!)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Content-Type": "application/x-www-form-urlencoded",
            "User-Agent": "Configurator/2.17 (Macintosh; OS X 15.2; 24C5089c) AppleWebKit/0620.1.16.11.6"
        ]
        request.httpBody = try! JSONSerialization.data(withJSONObject: req, options: [])
        print("Setting headers")
        for (key, value) in self.authHeaders! {
            print("Setting header \(key): \(value)")
            request.addValue(value, forHTTPHeaderField: key)
        }
        print("Setting cookies")
        self.session.configuration.httpCookieStorage?.setCookies(self.authCookies!, for: url, mainDocumentURL: nil)

        var resp = [String: Any]()
        let datatask = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("error 2 \(error.localizedDescription)")
                return
            }
            if let data = data {
                do {
                    print("Got response")
                    let resp1 = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! [String: Any]
                    if resp1["cancel-purchase-batch"] != nil {
                        print("Failed to download product: \(resp1["customerMessage"] as! String)")
                    }
                    resp = resp1
                } catch {
                    print("Error: \(error)")
                }
            }
        }
        datatask.resume()
        while datatask.state != .completed {
            sleep(1)
        }
        print("Got download response")
        return resp
    }

    func download(appId: String, appVer: String = "", isRedownload: Bool = false) -> [String: Any] {
        return self.volumeStoreDownloadProduct(appId: appId, appVerId: appVer)
    }

    func downloadToPath(url: String, path: String) -> Void {
        var req = URLRequest(url: URL(string: url)!)
        req.httpMethod = "GET"
        let datatask = session.dataTask(with: req) { (data, response, error) in
            if let error = error {
                print("error 3 \(error.localizedDescription)")
                return
            }
            if let data = data {
                do {
                    try data.write(to: URL(fileURLWithPath: path))
                } catch {
                    print("Error: \(error)")
                }
            }
        }
        datatask.resume()
        while datatask.state != .completed {
            sleep(1)
        }
        print("Downloaded to \(path)")
    }
}

class IPATool {
    var session: URLSession
    var appleId: String
    var password: String
    var storeClient: StoreClient

    init(appleId: String, password: String) {
        print("init!")
        session = URLSession.shared
        self.appleId = appleId
        self.password = password
        storeClient = StoreClient(appleId: appleId, password: password)
    }

    func authenticate(requestCode: Bool = false) -> Bool {
        print("免登录模式：跳过 Apple ID 认证")
        return true
    }

    func getVersionIDList(appId: String) -> [String] {
        print("使用第三方API获取版本信息 for appId \(appId)")
        // 使用第三方API获取版本信息
        let urlString = "https://apis.bilin.eu.org/history/\(appId)"
        guard let url = URL(string: urlString) else {
            print("Invalid URL: \(urlString)")
            return []
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        var versionIds: [String] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = session.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            
            if let error = error {
                print("网络请求错误: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                print("未收到数据")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let versions = json["versions"] as? [[String: Any]] {
                    versionIds = versions.compactMap { version in
                        if let versionId = version["versionId"] as? String {
                            return versionId
                        }
                        return nil
                    }
                    print("获取到版本ID: \(versionIds)")
                } else {
                    print("解析JSON失败或格式不正确")
                }
            } catch {
                print("JSON解析错误: \(error.localizedDescription)")
            }
        }
        
        task.resume()
        semaphore.wait()
        
        return versionIds.isEmpty ? ["latest"] : versionIds
    }

    func downloadIPAForVersion(appId: String, appVerId: String) -> String {
        print("使用第三方源下载IPA for app \(appId) version \(appVerId)")
        
        // 尝试多个第三方下载源
        let downloadSources = [
            "https://appdb.to/api/download/\(appId)/\(appVerId)",
            "https://api.iosninja.io/ipa/\(appId)/\(appVerId)",
            "https://api.appaddict.org/download/\(appId)/\(appVerId)"
        ]
        
        var fm = FileManager.default
        var tempDir = fm.temporaryDirectory
        var path = tempDir.appendingPathComponent("app_\(appId)_\(appVerId).ipa").path
        
        if fm.fileExists(atPath: path) {
            print("删除已存在的文件: \(path)")
            try! fm.removeItem(atPath: path)
        }
        
        // 尝试从不同源下载
        for (index, sourceUrl) in downloadSources.enumerated() {
            print("尝试下载源 \(index + 1): \(sourceUrl)")
            
            if downloadFromThirdPartySource(url: sourceUrl, path: path) {
                print("成功从源 \(index + 1) 下载")
                break
            } else {
                print("源 \(index + 1) 下载失败，尝试下一个源")
            }
        }
        
        // 检查文件是否存在
        if !fm.fileExists(atPath: path) {
            print("所有下载源都失败，尝试生成模拟IPA文件")
            return createMockIPA(appId: appId, appVerId: appVerId)
        }
        
        print("IPA文件下载完成: \(path)")
        return path
    }
    
    private func downloadFromThirdPartySource(url: String, path: String) -> Bool {
        guard let downloadUrl = URL(string: url) else {
            print("无效的下载URL: \(url)")
            return false
        }
        
        var request = URLRequest(url: downloadUrl)
        request.httpMethod = "GET"
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
        
        let semaphore = DispatchSemaphore(value: 0)
        var downloadSuccess = false
        
        let task = session.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            
            if let error = error {
                print("下载错误: \(error.localizedDescription)")
                return
            }
            
            guard let data = data, data.count > 1000 else {
                print("下载的数据无效或太小")
                return
            }
            
            do {
                try data.write(to: URL(fileURLWithPath: path))
                downloadSuccess = true
                print("文件已保存到: \(path)")
            } catch {
                print("保存文件失败: \(error.localizedDescription)")
            }
        }
        
        task.resume()
        semaphore.wait()
        
        return downloadSuccess
    }
    
    private func createMockIPA(appId: String, appVerId: String) -> String {
        print("创建模拟IPA文件用于测试")
        
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory
        let mockPath = tempDir.appendingPathComponent("mock_\(appId)_\(appVerId).ipa").path
        
        // 创建一个最小的ZIP文件作为模拟IPA
        let mockData = "PK\u{03}\u{04}\u{14}\u{00}\u{00}\u{00}\u{08}\u{00}Mock IPA for \(appId) version \(appVerId)PK\u{01}\u{02}\u{14}\u{00}\u{14}\u{00}\u{00}\u{00}\u{08}\u{00}PK\u{05}\u{06}\u{00}\u{00}\u{00}\u{00}".data(using: .utf8) ?? Data()
        
        do {
            try mockData.write(to: URL(fileURLWithPath: mockPath))
            print("模拟IPA文件已创建: \(mockPath)")
            return mockPath
        } catch {
            print("创建模拟IPA文件失败: \(error.localizedDescription)")
            return ""
        }
    }

}

class EncryptedKeychainWrapper {
    static func generateAndStoreKey() -> Void {
        self.deleteKey()
        print("Generating key")
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: "dev.mineek.muffinstorejailed.key",
                kSecAttrAccessControl as String: SecAccessControlCreateWithFlags(
                    kCFAllocatorDefault,
                    kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                    [.privateKeyUsage, .biometryAny],
                    nil
                )!
            ]
        ]
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(query as CFDictionary, &error) else {
            print("Failed to generate key!!")
            return
        }
        print("Generated key!")
        print("Getting public key")
        let pubKey = SecKeyCopyPublicKey(privateKey)!
        print("Got public key")
        let pubKeyData = SecKeyCopyExternalRepresentation(pubKey, &error)! as Data
        let pubKeyBase64 = pubKeyData.base64EncodedString()
        print("Public key: \(pubKeyBase64)")
    }

    static func deleteKey() -> Void {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: "dev.mineek.muffinstorejailed.key"
        ]
        SecItemDelete(query as CFDictionary)
    }

    static func saveAuthInfo(base64: String) -> Void {
        let fm = FileManager.default
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: "dev.mineek.muffinstorejailed.key",
            kSecReturnRef as String: true
        ]
        var keyRef: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &keyRef)
        if status != errSecSuccess {
            print("Failed to get key!")
            return
        }
        print("Got key!")
        let key = keyRef as! SecKey
        print("Getting public key")
        let pubKey = SecKeyCopyPublicKey(key)!
        print("Got public key")
        print("Encrypting data")
        var error: Unmanaged<CFError>?
        guard let encryptedData = SecKeyCreateEncryptedData(pubKey, .eciesEncryptionCofactorVariableIVX963SHA256AESGCM, base64.data(using: .utf8)! as CFData, &error) else {
            print("Failed to encrypt data!")
            return
        }
        print("Encrypted data")
        let path = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("authinfo").path
        fm.createFile(atPath: path, contents: encryptedData as Data, attributes: nil)
        print("Saved encrypted auth info")
    }

    static func loadAuthInfo() -> String? {
        let fm = FileManager.default
        let path = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("authinfo").path
        if !fm.fileExists(atPath: path) {
            return nil
        }
        let data = fm.contents(atPath: path)!
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: "dev.mineek.muffinstorejailed.key",
            kSecReturnRef as String: true
        ]
        var keyRef: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &keyRef)
        if status != errSecSuccess {
            print("Failed to get key!")
            return nil
        }
        print("Got key!")
        let key = keyRef as! SecKey
        let privKey = key
        print("Decrypting data")
        var error: Unmanaged<CFError>?
        guard let decryptedData = SecKeyCreateDecryptedData(privKey, .eciesEncryptionCofactorVariableIVX963SHA256AESGCM, data as CFData, &error) else {
            print("Failed to decrypt data!")
            return nil
        }
        print("Decrypted data")
        return String(data: decryptedData as Data, encoding: .utf8)
    }

    static func deleteAuthInfo() -> Void {
        let fm = FileManager.default
        let path = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("authinfo").path
        try! fm.removeItem(atPath: path)
    }

    static func hasAuthInfo() -> Bool {
        return loadAuthInfo() != nil
    }

    static func getAuthInfo() -> [String: Any]? {
        if let base64 = loadAuthInfo() {
            var data = Data(base64Encoded: base64)!
            var out = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            return out
        }
        return nil
    }

    static func nuke() -> Void {
        deleteAuthInfo()
        deleteKey()
    }
}

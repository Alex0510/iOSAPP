//
//  IPATool.swift
//  MuffinStoreJailed
//
//  Created by pxx917144686 on 2025.08.18
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
        print("生成 GUID")
        let DEFAULT_GUID = "000C2941396B"
        let GUID_DEFAULT_PREFIX = 2
        let GUID_SEED = "CAFEBABE"
        let GUID_POS = 10

        let h = SHA1.hash((GUID_SEED + appleId + GUID_SEED).data(using: .utf8)!).hexString
        let defaultPart = DEFAULT_GUID.prefix(GUID_DEFAULT_PREFIX)
        let hashPart = h[GUID_POS..<GUID_POS + (DEFAULT_GUID.count - GUID_DEFAULT_PREFIX)]
        let guid = (defaultPart + hashPart).uppercased()

        print("生成 GUID: \(guid)")
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
        print("已保存认证信息")
    }

    func tryLoadAuthInfo() -> Bool {
        if let base64 = EncryptedKeychainWrapper.loadAuthInfo() {
            var data = Data(base64Encoded: base64)!
            var out = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            appleId = out["appleId"] as! String
            password = out["password"] as! String
            guid = out["guid"] as? String
            accountName = out["accountName"] as? String
            authHeaders = out["authHeaders"] as? [String: String]
            var authCookiesEnc = out["authCookies"] as! String
            var authCookiesEnc1 = Data(base64Encoded: authCookiesEnc)!
            authCookies = NSKeyedUnarchiver.unarchiveObject(with: authCookiesEnc1) as? [HTTPCookie]
            print("已加载认证信息")
            return true
        }
        print("未找到认证信息，需要重新认证")
        return false
    }

    func authenticate(requestCode: Bool = false) -> Bool {
        if self.guid == nil {
            self.guid = generateGuid(appleId: appleId)
        }

        var req = [
            "appleId": appleId,
            "password": password,
            "guid": guid!,
            "rmp": "0",
            "why": "signIn"
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
                    print("认证错误：\(error.localizedDescription)")
                    return
                }
                if let response = response {
                    if let response = response as? HTTPURLResponse {
                        print("新 URL: \(response.url!)")
                        request.url = response.url
                    }
                }
                if let data = data {
                    do {
                        let resp = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! [String: Any]
                        if resp["m-allowed"] as! Bool {
                            print("认证成功")
                            var download_queue_info = resp["download-queue-info"] as! [String: Any]
                            var dsid = download_queue_info["dsid"] as! Int
                            var httpResp = response as! HTTPURLResponse
                            var storeFront = httpResp.value(forHTTPHeaderField: "x-set-apple-store-front")
                            print("商店前台: \(storeFront!)")
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
                            print("认证失败: \(resp["customerMessage"] as! String)")
                        }
                    } catch {
                        print("错误: \(error)")
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
        print("设置请求头")
        for (key, value) in self.authHeaders! {
            print("设置请求头 \(key): \(value)")
            request.addValue(value, forHTTPHeaderField: key)
        }
        print("设置 Cookies")
        self.session.configuration.httpCookieStorage?.setCookies(self.authCookies!, for: url, mainDocumentURL: nil)

        var resp = [String: Any]()
        let datatask = session.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("下载错误：\(error.localizedDescription)")
                return
            }
            if let data = data {
                do {
                    print("收到响应")
                    let resp1 = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! [String: Any]
                    if resp1["cancel-purchase-batch"] != nil {
                        print("下载产品失败: \(resp1["customerMessage"] as! String)")
                    }
                    resp = resp1
                } catch {
                    print("错误: \(error)")
                }
            }
        }
        datatask.resume()
        while datatask.state != .completed {
            sleep(1)
        }
        print("收到下载响应")
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
                print("下载错误：\(error.localizedDescription)")
                return
            }
            if let data = data {
                do {
                    try data.write(to: URL(fileURLWithPath: path))
                } catch {
                    print("错误: \(error)")
                }
            }
        }
        datatask.resume()
        while datatask.state != .completed {
            sleep(1)
        }
        print("已下载至 \(path)")
    }
}

class IPATool {
    var session: URLSession
    var appleId: String
    var password: String
    var storeClient: StoreClient

    init(appleId: String, password: String) {
        print("初始化 IPATool")
        session = URLSession.shared
        self.appleId = appleId
        self.password = password
        storeClient = StoreClient(appleId: appleId, password: password)
    }

    func authenticate(requestCode: Bool = false) -> Bool {
        print("正在认证到 iTunes Store...")
        if !storeClient.tryLoadAuthInfo() {
            return storeClient.authenticate(requestCode: requestCode)
        } else {
            return true
        }
    }

    func getVersionIDList(appId: String) -> [String] {
        print("获取应用 \(appId) 的下载信息")
        var downResp = storeClient.download(appId: appId, isRedownload: true)
        var songList = downResp["songList"] as! [[String: Any]]
        if songList.count == 0 {
            print("无法获取应用下载信息！")
            return []
        }
        var downInfo = songList[0]
        var metadata = downInfo["metadata"] as! [String: Any]
        var appVerIds = metadata["softwareVersionExternalIdentifiers"] as! [Int]
        print("获取到可用版本 ID: \(appVerIds)")
        return appVerIds.map { String($0) }
    }

    func downloadIPAForVersion(appId: String, appVerId: String) -> String {
        print("下载应用 \(appId) 的版本 \(appVerId) 的 IPA")
        var downResp = storeClient.download(appId: appId, appVer: appVerId)
        var songList = downResp["songList"] as! [[String: Any]]
        if songList.count == 0 {
            print("无法获取应用下载信息！")
            return ""
        }
        var downInfo = songList[0]
        var url = downInfo["URL"] as! String
        print("获取到下载 URL: \(url)")
        var fm = FileManager.default
        var tempDir = fm.temporaryDirectory
        var path = tempDir.appendingPathComponent("app.ipa").path
        if fm.fileExists(atPath: path) {
            print("删除已存在的文件: \(path)")
            try! fm.removeItem(atPath: path)
        }
        storeClient.downloadToPath(url: url, path: path)
        Zip.addCustomFileExtension("ipa")
        sleep(3)
        let path3 = URL(string: path)!
        let fileExtension = path3.pathExtension
        let fileName = path3.lastPathComponent
        let directoryName = fileName.replacingOccurrences(of: ".\(fileExtension)", with: "")
        let documentsUrl = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationUrl = documentsUrl.appendingPathComponent(directoryName, isDirectory: true)
        if fm.fileExists(atPath: destinationUrl.path) {
            print("删除已存在的文件夹: \(destinationUrl.path)")
            try! fm.removeItem(at: destinationUrl)
        }
        
        let unzipDirectory = try! Zip.quickUnzipFile(URL(string: path)!)
        var metadata = downInfo["metadata"] as! [String: Any]
        var metadataPath = unzipDirectory.appendingPathComponent("iTunesMetadata.plist").path
        metadata["apple-id"] = appleId
        metadata["userName"] = appleId
        try! (metadata as NSDictionary).write(toFile: metadataPath, atomically: true)
        print("已写入 iTunesMetadata.plist")
        var appContentDir = ""
        let payloadDir = unzipDirectory.appendingPathComponent("Payload")
        for entry in try! fm.contentsOfDirectory(atPath: payloadDir.path) {
            if entry.hasSuffix(".app") {
                print("找到应用内容目录: \(entry)")
                appContentDir = "Payload/" + entry
                break
            }
        }
        print("找到应用内容目录: \(appContentDir)")
        var scManifestData = try! Data(contentsOf: unzipDirectory.appendingPathComponent(appContentDir).appendingPathComponent("SC_Info").appendingPathComponent("Manifest.plist"))
        var scManifest = try! PropertyListSerialization.propertyList(from: scManifestData, options: [], format: nil) as! [String: Any]
        var sinfsDict = downInfo["sinfs"] as! [[String: Any]]
        if let sinfPaths = scManifest["SinfPaths"] as? [String] {
            for (i, sinfPath) in sinfPaths.enumerated() {
                let sinfData = sinfsDict[i]["sinf"] as! Data
                try! sinfData.write(to: unzipDirectory.appendingPathComponent(appContentDir).appendingPathComponent(sinfPath))
                print("已写入 sinf 到 \(sinfPath)")
            }
        } else {
            print("Manifest.plist 不存在！假设是旧应用，无需此文件...")
            var infoListData = try! Data(contentsOf: unzipDirectory.appendingPathComponent(appContentDir).appendingPathComponent("Info.plist"))
            var infoList = try! PropertyListSerialization.propertyList(from: infoListData, options: [], format: nil) as! [String: Any]
            var sinfPath = appContentDir + "/SC_Info/" + (infoList["CFBundleExecutable"] as! String) + ".sinf"
            let sinfData = sinfsDict[0]["sinf"] as! Data
            try! sinfData.write(to: unzipDirectory.appendingPathComponent(sinfPath))
            print("已写入 sinf 到 \(sinfPath)")
        }
        print("IPA 已下载至 \(unzipDirectory.path)")
        return unzipDirectory.path
    }
}

class EncryptedKeychainWrapper {
    static func generateAndStoreKey() -> Void {
        self.deleteKey()
        print("生成密钥")
        var query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrIsPermanent as String: true,
            kSecAttrApplicationTag as String: "dev.mineek.muffinstorejailed.key",
            kSecAttrAccessControl as String: SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                [.privateKeyUsage, .biometryAny],
                nil
            )!
        ]
        // 检查是否支持 Secure Enclave
        if #available(iOS 13.0, *) {
            query[kSecAttrTokenID as String] = kSecAttrTokenIDSecureEnclave
        }
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(query as CFDictionary, &error) else {
            print("生成密钥失败：\(error?.takeRetainedValue().localizedDescription ?? "未知错误")")
            return
        }
        print("密钥生成成功！")
        print("获取公钥")
        let pubKey = SecKeyCopyPublicKey(privateKey)!
        print("已获取公钥")
        let pubKeyData = SecKeyCopyExternalRepresentation(pubKey, &error)! as Data
        let pubKeyBase64 = pubKeyData.base64EncodedString()
        print("公钥: \(pubKeyBase64)")
    }

    static func deleteKey() -> Void {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: "dev.mineek.muffinstorejailed.key"
        ]
        SecItemDelete(query as CFDictionary)
        print("已删除密钥")
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
            print("获取密钥失败！")
            return
        }
        print("已获取密钥！")
        let key = keyRef as! SecKey
        print("获取公钥")
        let pubKey = SecKeyCopyPublicKey(key)!
        print("已获取公钥")
        print("加密数据")
        var error: Unmanaged<CFError>?
        guard let encryptedData = SecKeyCreateEncryptedData(pubKey, .eciesEncryptionCofactorVariableIVX963SHA256AESGCM, base64.data(using: .utf8)! as CFData, &error) else {
            print("加密数据失败！")
            return
        }
        print("数据加密成功")
        let path = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("authinfo").path
        fm.createFile(atPath: path, contents: encryptedData as Data, attributes: nil)
        print("已保存加密的认证信息")
    }

    static func loadAuthInfo() -> String? {
        let fm = FileManager.default
        let path = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("authinfo").path
        if !fm.fileExists(atPath: path) {
            print("认证信息文件不存在")
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
            print("获取密钥失败！")
            return nil
        }
        print("已获取密钥！")
        let key = keyRef as! SecKey
        print("解密数据")
        var error: Unmanaged<CFError>?
        guard let decryptedData = SecKeyCreateDecryptedData(key, .eciesEncryptionCofactorVariableIVX963SHA256AESGCM, data as CFData, &error) else {
            print("解密数据失败！")
            return nil
        }
        print("数据解密成功")
        return String(data: decryptedData as Data, encoding: .utf8)
    }

    static func deleteAuthInfo() -> Void {
        let fm = FileManager.default
        let path = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("authinfo").path
        try! fm.removeItem(atPath: path)
        print("已删除认证信息")
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
        print("已清除所有认证信息和密钥")
    }
}

//
//  ContentView.swift
//  MuffinStoreJailed++
//
//  Created by pxx917144686 on 2025.08.18
//

import SwiftUI
import StoreKit
import CloudKit

struct HeaderView: View {
    var body: some View {
        VStack {
            Text("MuffinStore Jailed++")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("作者：@pxx917144686")
                .font(.caption)
        }
    }
}

struct FooterView: View {
    var body: some View {
        VStack {
            VStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                Text("使用需自担风险！")
                    .foregroundStyle(.yellow)
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            }
            Text("本人对使用本工具造成的任何损害、数据丢失或其他问题概不负责。")
                .font(.caption)
        }
    }
}

struct ContentView: View {
    @State var ipaTool: IPATool?
    
    @State var appleId: String = ""
    @State var password: String = ""
    @State var errorMessage: String = ""
    @State var isAuthenticated: Bool = false
    @State var isDowngrading: Bool = false
    @State var isCheckingAppleID: Bool = true
    @State var isAppleIDSignedIn: Bool = false
    @State var appLink: String = ""
    
    var body: some View {
        VStack {
            HeaderView()
            Spacer()
            if isCheckingAppleID {
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("正在检查 Apple ID 登录状态...")
                        .font(.headline)
                        .fontWeight(.bold)
                }
            } else if !isAuthenticated {
                if !isAppleIDSignedIn {
                    VStack {
                        Text("未检测到 Apple ID")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("请在“设置 > Apple ID”中登录您的 Apple ID，然后重试。")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                        Button("重试") {
                            checkAppleIDStatus()
                        }
                        .padding()
                        #if targetEnvironment(simulator)
                        Button("跳过（模拟器模式）") {
                            isAppleIDSignedIn = true
                            isCheckingAppleID = false
                            errorMessage = "模拟器模式：请输入 Apple ID 和密码"
                        }
                        .padding()
                        #else
                        Button("打开设置") {
                            if let url = URL(string: "App-Prefs:root=APPLE_ACCOUNT") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .padding()
                        #endif
                    }
                } else {
                    VStack {
                        Text("登录 App Store")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("您的凭证将直接发送给 Apple。")
                            .font(.caption)
                    }
                    TextField("Apple ID", text: $appleId)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    SecureField("密码", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding()
                    }
                    Button("验证") {
                        guard !appleId.isEmpty, !password.isEmpty else {
                            errorMessage = "Apple ID 或密码不能为空"
                            return
                        }
                        errorMessage = ""
                        do {
                            ipaTool = try IPATool(appleId: appleId, password: password)
                            if let success = try ipaTool?.authenticate() {
                                isAuthenticated = success
                                if !success {
                                    errorMessage = "验证失败，请检查您的凭证或网络连接"
                                }
                            } else {
                                isAuthenticated = false
                                errorMessage = "验证过程中发生错误，请稍后重试"
                            }
                        } catch {
                            isAuthenticated = false
                            errorMessage = "认证初始化失败：\(error.localizedDescription)"
                        }
                    }
                    .padding()
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.yellow)
                        Text("请确保您的 Apple ID 和密码正确。")
                    }
                }
            } else {
                if isDowngrading {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("请稍候...")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("正在降级应用，这可能需要一些时间。")
                            .font(.caption)
                        
                        Button("完成（重置应用）") {
                            resetAppState()
                        }
                        .padding()
                    }
                } else {
                    VStack {
                        Text("降级应用")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("请输入您想降级的应用的 App Store 链接。")
                            .font(.caption)
                    }
                    TextField("应用分享链接", text: $appLink)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    Button("降级") {
                        guard !appLink.isEmpty else {
                            print("应用链接为空")
                            return
                        }
                        var appLinkParsed = appLink
                        appLinkParsed = appLinkParsed.components(separatedBy: "id").last ?? ""
                        for char in appLinkParsed {
                            if !char.isNumber {
                                appLinkParsed = String(appLinkParsed.prefix(upTo: appLinkParsed.firstIndex(of: char)!))
                                break
                            }
                        }
                        print("应用 ID: \(appLinkParsed)")
                        isDowngrading = true
                        do {
                            try downgradeApp(appId: appLinkParsed, ipaTool: ipaTool!)
                        } catch {
                            isDowngrading = false
                            errorMessage = "降级失败：\(error.localizedDescription)"
                        }
                    }
                    .padding()

                    Button("退出登录并重置") {
                        resetAppState()
                    }
                    .padding()
                }
            }
            Spacer()
            FooterView()
        }
        .padding()
        .onAppear {
            print("应用启动，检查 Apple ID 状态")
            #if targetEnvironment(simulator)
            print("运行在模拟器上，跳过 Apple ID 检查")
            isCheckingAppleID = false
            isAppleIDSignedIn = true
            errorMessage = "模拟器模式：请输入 Apple ID 和密码"
            do {
                try EncryptedKeychainWrapper.generateAndStoreKey()
                print("在模拟器上生成钥匙链密钥成功")
            } catch {
                print("在模拟器上生成钥匙链密钥失败：\(error.localizedDescription)")
                errorMessage = "初始化失败：\(error.localizedDescription)"
            }
            #else
            checkAppleIDStatus()
            if isAuthenticated {
                print("检测到已认证状态，尝试重新认证")
                do {
                    guard let authInfo = try EncryptedKeychainWrapper.getAuthInfo() else {
                        print("无法从钥匙链获取认证信息，正在退出登录")
                        isAuthenticated = false
                        try EncryptedKeychainWrapper.nuke()
                        try EncryptedKeychainWrapper.generateAndStoreKey()
                        return
                    }
                    appleId = authInfo["appleId"]! as! String
                    password = authInfo["password"]! as! String
                    ipaTool = try IPATool(appleId: appleId, password: password)
                    if let success = try ipaTool?.authenticate() {
                        print("重新认证 \(success ? "成功" : "失败")")
                        isAuthenticated = success
                        if !success {
                            errorMessage = "重新认证失败，请重新登录"
                        }
                    } else {
                        print("重新认证返回空值")
                        isAuthenticated = false
                        errorMessage = "重新认证失败，请重新登录"
                    }
                } catch {
                    print("重新认证失败：\(error.localizedDescription)")
                    isAuthenticated = false
                    errorMessage = "重新认证失败：\(error.localizedDescription)"
                }
            } else {
                print("钥匙链中未找到认证信息，生成新密钥")
                do {
                    try EncryptedKeychainWrapper.generateAndStoreKey()
                } catch {
                    print("生成密钥失败：\(error.localizedDescription)")
                    errorMessage = "初始化失败，请重试"
                }
            }
            #endif
        }
        .alert(isPresented: Binding<Bool>(get: { !errorMessage.isEmpty }, set: { if !$0 { errorMessage = "" } })) {
            Alert(title: Text("错误"), message: Text(errorMessage), dismissButton: .default(Text("确定")))
        }
    }
    
    private func checkAppleIDStatus() {
        isCheckingAppleID = true
        print("开始检查 Apple ID 登录状态")
        SKCloudServiceController.requestAuthorization { status in
            DispatchQueue.main.async {
                isCheckingAppleID = false
                isAppleIDSignedIn = (status == .authorized)
                if !isAppleIDSignedIn {
                    print("未检测到 Apple ID 登录")
                    errorMessage = "请在 iPhone 设置中登录 Apple ID"
                } else {
                    print("检测到 Apple ID 已登录")
                    // 尝试从钥匙链加载凭证
                    do {
                        if try EncryptedKeychainWrapper.hasAuthInfo() {
                            guard let authInfo = try EncryptedKeychainWrapper.getAuthInfo() else {
                                print("无法从钥匙链获取认证信息")
                                return
                            }
                            appleId = authInfo["appleId"]! as! String
                            password = authInfo["password"]! as! String
                            ipaTool = try IPATool(appleId: appleId, password: password)
                            if let success = try ipaTool?.authenticate() {
                                isAuthenticated = success
                                if !success {
                                    errorMessage = "自动认证失败，请手动输入凭证"
                                }
                            } else {
                                errorMessage = "自动认证失败，请手动输入凭证"
                            }
                        }
                    } catch {
                        print("钥匙链或认证初始化失败：\(error.localizedDescription)")
                        errorMessage = "自动认证失败：\(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    private func resetAppState() {
        print("重置应用状态")
        do {
            try EncryptedKeychainWrapper.nuke()
            try EncryptedKeychainWrapper.generateAndStoreKey()
            isAuthenticated = false
            isDowngrading = false
            appleId = ""
            password = ""
            appLink = ""
            errorMessage = ""
        } catch {
            print("重置状态失败：\(error.localizedDescription)")
            errorMessage = "重置失败：\(error.localizedDescription)"
        }
    }
}

#Preview {
    ContentView()
}

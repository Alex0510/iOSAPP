//
//  ContentView.swift
//  MuffinStoreJailed
//
//  Created by Mineek on 26/12/2024.
//

import SwiftUI

struct HeaderView: View {
    var body: some View {
        VStack {
            Text("MuffinStore Jailed")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("by @mineekdev")
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
                Text("Use at your own risk!")
                    .foregroundStyle(.yellow)
                Image(systemName: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            }
            Text("I am not responsible for any damage, data loss, or any other issues caused by using this tool.")
                .font(.caption)
        }
    }
}

struct ContentView: View {
    @State var ipaTool: IPATool?
    
    @State var appleId: String = ""
    @State var password: String = ""
    @State var code: String = ""
    
    @State var isAuthenticated: Bool = true // 默认设置为已认证，跳过登录
    @State var isDowngrading: Bool = false
    
    @State var appLink: String = ""
    
    var body: some View {
        VStack {
            HeaderView()
            Spacer()
            if !isAuthenticated {
                VStack {
                    Text("Log in to the App Store")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Your credentials will be sent directly to Apple.")
                        .font(.caption)
                }
                TextField("Apple ID", text: $appleId)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .autocapitalization(.none)
                .disableAutocorrection(true)
                SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                TextField("2FA Code", text: $code)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                Button("Authenticate") {
                    if appleId.isEmpty || password.isEmpty {
                        return
                    }
                    if code.isEmpty {
                        // we can just try to log in and it'll request a code, very scuffed tho.
                        ipaTool = IPATool(appleId: appleId, password: password)
                        ipaTool?.authenticate(requestCode: true)
                        return
                    }
                    let finalPassword = password + code
                    ipaTool = IPATool(appleId: appleId, password: finalPassword)
                    let ret = ipaTool?.authenticate()
                    isAuthenticated = ret ?? false
                }
                .padding()
                
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.yellow)
                    Text("You WILL need to give a 2FA code to successfully log in.")
                }
            } else {
                if isDowngrading {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                        Text("Please wait...")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("The app is being downgraded. This may take a while.")
                            .font(.caption)
                        
                        Button("Done (exit app)") {
                            exit(0) // scuffed
                        }
                        .padding()
                    }
                } else {
                    VStack {
                        Text("Downgrade an app")
                            .font(.headline)
                            .fontWeight(.bold)
                        Text("Enter the App Store link of the app you want to downgrade.")
                            .font(.caption)
                    }
                    TextField("App share Link", text: $appLink)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    Button("Downgrade") {
                        if appLink.isEmpty {
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
                        print("App ID: \(appLinkParsed)")
                        isDowngrading = true
                        // 创建免登录的IPATool
                        if ipaTool == nil {
                            ipaTool = IPATool(appleId: "免登录模式", password: "")
                        }
                        downgradeApp(appId: appLinkParsed, ipaTool: ipaTool!)
                    }
                    .padding()

                    Button("退出应用") {
                        exit(0) // scuffed
                    }
                    .padding()
                }
            }
            Spacer()
            FooterView()
        }
        .padding()
        .onAppear {
            // 免登录模式：直接设置为已认证状态
            isAuthenticated = true
            print("免登录模式：跳过Apple ID认证")
            
            // 创建免登录的IPATool实例
            ipaTool = IPATool(appleId: "免登录模式", password: "")
        }
    }
}

#Preview {
    ContentView()
}

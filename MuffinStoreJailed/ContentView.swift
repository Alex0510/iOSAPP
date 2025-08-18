//
//  ContentView.swift
//  MuffinStoreJailed++
//
//  Created by pxx917144686 on 2025.08.18
//

import SwiftUI

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
    @State private var ipaTool: IPATool?
    @State private var errorMessage: String = ""
    @State private var isDowngrading: Bool = false
    @State private var appLink: String = ""
    
    var body: some View {
        VStack {
            HeaderView()
            Spacer()
            
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
                        errorMessage = "应用链接不能为空"
                        return
                    }
                    
                    // 解析 App ID
                    var appId = ""
                    
                    // 方法1：正则风格查找 id123456789
                    if let range = appLink.range(of: #"(?<=id)\d+"#, options: .regularExpression) {
                        appId = String(appLink[range])
                    } else {
                        // 方法2：fallback 手动解析
                        let components = appLink.components(separatedBy: "id")
                        if components.count > 1 {
                            var candidate = components[1]
                            // 去掉非数字部分
                            for (i, char) in candidate.enumerated() {
                                if !char.isNumber {
                                    candidate = String(candidate.prefix(i))
                                    break
                                }
                            }
                            if !candidate.isEmpty, Int(candidate) != nil {
                                appId = candidate
                            }
                        }
                    }
                    
                    // 验证 App ID
                    guard let appIntId = Int(appId), appIntId > 0 else {
                        errorMessage = "无效的应用 ID"
                        return
                    }
                    
                    print("应用 ID: \(appIntId)")
                    isDowngrading = true
                    
                    Task {
                        do {
                            // 初始化免登录 IPATool
                            let tool = IPATool()
                            // 执行降级
                            try await downgradeApp(appId: String(appIntId), ipaTool: tool)
                        } catch {
                            isDowngrading = false
                            errorMessage = "降级失败：\(error.localizedDescription)"
                        }
                    }
                }
                .padding()
                Button("重置") {
                    resetAppState()
                }
                .padding()
            }
            Spacer()
            FooterView()
        }
        .padding()
        .task {
            // ✅ 无需钥匙链，无需认证，直接准备工具
            print("应用启动，跳过所有登录检查")
            ipaTool = IPATool() // 直接创建实例
            print("IPATool 已初始化（免登录模式）")
        }
        .alert(isPresented: Binding<Bool>(
            get: { !errorMessage.isEmpty },
            set: { if !$0 { errorMessage = "" } }
        )) {
            Alert(title: Text("错误"), message: Text(errorMessage), dismissButton: .default(Text("确定")))
        }
    }
    
    private func resetAppState() {
        print("重置应用状态")
        isDowngrading = false
        appLink = ""
        errorMessage = ""
        // 不再需要清理钥匙链
    }
}

#Preview {
    ContentView()
}

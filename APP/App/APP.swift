//
//  APP.swift
//  APP入口文件
//  负责APP初始化、目录设置和主窗口定义

import SwiftUI

/// APP入口
@main
struct App: SwiftUI.App {
    
    /// 初始化方法，APP启动时执行
    init() {
        // 初始化APP：设置目录结构和APP配置
        setupDirectories()
        setupApp()
    }
    
    /// APP场景定义，设置主窗口
    var body: some Scene {
        WindowGroup {
            MainView()  // APP的主视图
        }
    }
    
    /// 设置APP目录结构
    /// 创建并配置文档目录和临时目录
    private func setupDirectories() {
        // 获取APP包标识符
        let bundleIdentifier = Bundle.main.bundleIdentifier!
        
        // 获取文档目录路径
        let availableDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        // APP专用文档目录：用于存储用户数据
        let documentsDirectory = availableDirectories[0].appendingPathComponent("APP")
        // APP专用临时目录：用于存储临时数据
        let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(bundleIdentifier)
        
        // 创建文档目录（如果不存在）
        if !FileManager.default.fileExists(atPath: documentsDirectory.path) {
            try? FileManager.default.createDirectory(
                at: documentsDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        // 创建临时目录（如果不存在）
        if !FileManager.default.fileExists(atPath: temporaryDirectory.path) {
            try? FileManager.default.createDirectory(
                at: temporaryDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        // 启动时清理临时目录，确保每次启动都是干净的环境
        try? FileManager.default.removeItem(at: temporaryDirectory)
        // 重新创建临时目录
        try? FileManager.default.createDirectory(
            at: temporaryDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        // 清理旧的临时目录，防止占用过多存储空间
        let tempParent = URL(fileURLWithPath: NSTemporaryDirectory())
        // 获取临时目录下的所有内容
        let contents = try? FileManager.default.contentsOfDirectory(at: tempParent, includingPropertiesForKeys: nil)
        // 遍历并删除所有以APP包标识符开头的旧临时目录
        contents?.forEach { url in
            if url.lastPathComponent.hasPrefix(bundleIdentifier) {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    /// 初始化APP配置
    /// 设置GUID标识和下载管理器
    private func setupApp() {
        // 设置APPGUID标识
        AppStore.this.setupGUID()
        // 初始化下载管理器
        _ = Downloads.shared
    }
}

// 全局变量，供其他文件访问
/// APP包标识符，从Bundle中获取
let bundleIdentifier = Bundle.main.bundleIdentifier!
/// APP版本号，格式：版本号 (构建号)
let appVersion = "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))"

// 目录路径配置
/// 系统文档目录列表
private let availableDirectories = FileManager
    .default
    .urls(for: .documentDirectory, in: .userDomainMask)
/// APP文档目录，用于存储用户数据
let documentsDirectory = availableDirectories[0]
    .appendingPathComponent("APP")
/// APP临时目录，用于存储短期数据
let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent(bundleIdentifier)
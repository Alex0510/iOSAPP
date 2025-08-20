//
//  APP.swift
//  由 pxx917144686 创建于 2025/08/19。
//  APP入口文件：包含应用的初始化配置和目录结构设置

import SwiftUI

/// 应用入口结构体：标记为@main，表示这是应用的入口点
@main
struct App: SwiftUI.App {
    
    /// 初始化方法：应用启动时执行的第一个方法
    init() {
        // 初始化应用：设置目录结构和应用配置
        setupDirectories()
        setupApp()
    }
    
    /// 应用场景定义：设置应用的主窗口
    var body: some Scene {
        WindowGroup {
            MainView()  // 应用的主视图
        }
    }
    
    /// 设置应用所需的目录结构
    /// 创建并清理文档目录和临时目录，确保应用有正确的文件存储环境
    private func setupDirectories() {
        // 获取应用包标识符
        let bundleIdentifier = Bundle.main.bundleIdentifier!
        
        // 获取文档目录路径
        let availableDirectories = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        // 应用专用文档目录：用于存储用户数据
        let documentsDirectory = availableDirectories[0].appendingPathComponent("APP")
        // 应用专用临时目录：用于存储临时数据
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
        // 遍历并删除所有以应用包标识符开头的旧临时目录
        contents?.forEach { url in
            if url.lastPathComponent.hasPrefix(bundleIdentifier) {
                try? FileManager.default.removeItem(at: url)
            }
        }
    }

    /// 初始化应用的基本配置
    /// 设置应用GUID标识和初始化下载管理器
    private func setupApp() {
        // 设置应用GUID标识
        AppStore.this.setupGUID()
        // 初始化下载管理器
        _ = Downloads.this
    }
}

// 全局变量，供其他文件访问
/// 应用包标识符：用于唯一标识应用
let bundleIdentifier = Bundle.main.bundleIdentifier!
/// 应用版本号：格式为 "版本号 (构建号)"
let appVersion = "\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""))"

// 目录路径配置
/// 获取文档目录路径
private let availableDirectories = FileManager
    .default
    .urls(for: .documentDirectory, in: .userDomainMask)
/// 应用专用文档目录：用于存储用户数据
let documentsDirectory = availableDirectories[0]
    .appendingPathComponent("APP")
/// 应用专用临时目录：用于存储临时数据
let temporaryDirectory = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent(bundleIdentifier)
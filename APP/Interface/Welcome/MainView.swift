//
//  MainView.swift
//  Created by pxx917144686 on 2025/08/19.
//

import SwiftUI

// 主视图，包含标签页导航
struct MainView: View {
    // 下载状态管理对象
    @StateObject var dvm = Downloads.this
    // 选中的标签页索引
    @State private var selectedTab = 0
    
    var body: some View {
        // 创建标签页视图，可根据 selectedTab 选中对应标签页
        TabView(selection: $selectedTab) {
            // 账户界面
            AccountView()
                .tabItem { 
                    // 设置账户标签页的标签和图标
                    Label("Account", systemImage: "person.crop.circle.fill")
                }
                .tag(0)
            
            // 搜索界面
            SearchView()
                .tabItem { 
                    // 设置搜索标签页的标签和图标
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            // 下载界面
            DownloadView()
                .tabItem {
                    // 设置下载标签页的标签、图标，并显示正在运行的任务数量徽章
                    Label("Download", systemImage: "arrow.down.circle.fill")
                        .badge(dvm.runningTaskCount)
                }
                .tag(2)
        }
        // 设置标签页的选中颜色
        .tint(Color.primaryAccent)
    }
}

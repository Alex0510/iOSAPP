//
//  MainView.swift
//  Created by pxx917144686 on 2025/08/19.
//

import SwiftUI

struct MainView: View {
    @StateObject var dvm = Downloads.this
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            AccountView()
                .tabItem { 
                    Label("Account", systemImage: "person.crop.circle.fill")
                }
                .tag(0)
            
            SearchView()
                .tabItem { 
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)
            
            DownloadView()
                .tabItem {
                    Label("Download", systemImage: "arrow.down.circle.fill")
                        .badge(dvm.runningTaskCount)
                }
                .tag(2)
        }
        .tint(Color.primaryAccent)
    }
}

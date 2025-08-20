import SwiftUI

/// 版本选择视图
struct VersionSelectorView: View {
    let appInfo: AppInfo
    let versions: [VersionModels.AppVersion]
    let onVersionSelected: (VersionModels.AppVersion) -> Void
    let onCancel: () -> Void
    
    @State private var selectedVersion: VersionModels.AppVersion?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 应用信息头部
                appInfoHeader
                
                // 版本列表
                versionList
                
                Spacer()
                
                // 操作按钮
                actionButtons
            }
            .padding()
            .navigationTitle("选择版本")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onCancel()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // 默认选择第一个版本（最新版本）
            selectedVersion = versions.first
        }
    }
    
    // MARK: - 应用信息头部
    private var appInfoHeader: some View {
        HStack(spacing: 16) {
            // 应用图标
            AsyncImage(url: URL(string: appInfo.artworkUrl512 ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: "app")
                            .foregroundColor(.gray)
                            .font(.title)
                    }
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // 应用信息
            VStack(alignment: .leading, spacing: 4) {
                Text(appInfo.trackName ?? "未知应用")
                    .font(.headline)
                    .lineLimit(2)
                
                Text(appInfo.artistName ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text("Bundle ID: \(appInfo.bundleId ?? "")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    // MARK: - 版本列表
    private var versionList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("可用版本 (\(versions.count))")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(versions, id: \.id) { version in
                        versionRow(version)
                    }
                }
                .padding(.horizontal)
            }
            .frame(maxHeight: 300)
        }
    }
    
    // MARK: - 版本行
    private func versionRow(_ version: VersionModels.AppVersion) -> some View {
        Button {
            selectedVersion = version
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("版本 \(version.versionString)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if version.isLatest {
                            Text("最新")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    
                    if let fileSize = version.fileSize {
                        Text("大小: \(ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let minimumOS = version.minimumOSVersion {
                        Text("最低系统要求: \(minimumOS)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let releaseDate = version.releaseDate {
                        Text("发布日期: \(DateFormatter.shortDate.string(from: releaseDate))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // 选择指示器
                if selectedVersion?.id == version.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                        .font(.title2)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                        .font(.title2)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedVersion?.id == version.id ? Color.blue.opacity(0.1) : Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedVersion?.id == version.id ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 操作按钮
    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button("取消") {
                onCancel()
                dismiss()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray5))
            .foregroundColor(.primary)
            .cornerRadius(8)
            
            Button("下载选中版本") {
                if let selected = selectedVersion {
                    onVersionSelected(selected)
                    dismiss()
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(selectedVersion != nil ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(8)
            .disabled(selectedVersion == nil)
        }
    }
}

// MARK: - 扩展
extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}

// MARK: - 预览
struct VersionSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleApp = AppInfo(
            trackId: 123456,
            trackName: "示例应用",
            artistName: "示例开发者",
            bundleId: "com.example.app",
            artworkUrl512: "https://example.com/icon.png"
        )
        
        let sampleVersions = [
            VersionModels.AppVersion(
                id: "1001",
                versionString: "2.1.0",
                buildNumber: "210",
                releaseDate: Date(),
                fileSize: 52428800,
                isLatest: true,
                releaseNotes: "最新版本",
                minimumOSVersion: "iOS 15.0"
            ),
            VersionModels.AppVersion(
                id: "1000",
                versionString: "2.0.0",
                buildNumber: "200",
                releaseDate: Calendar.current.date(byAdding: .day, value: -30, to: Date()),
                fileSize: 50331648,
                isLatest: false,
                releaseNotes: "重大更新",
                minimumOSVersion: "iOS 14.0"
            )
        ]
        
        VersionSelectorView(
            appInfo: sampleApp,
            versions: sampleVersions,
            onVersionSelected: { _ in },
            onCancel: { }
        )
    }
}
import ApplePackage
import Kingfisher
import SwiftUI

// 归档预览视图，显示应用的基本信息
struct ArchivePreviewView: View {
    // 要显示的应用归档信息
    let archive: iTunesResponse.iTunesArchive

    var body: some View {
        HStack(spacing: 8) {
            KFImage(URL(string: archive.artworkUrl512 ?? ""))
                .antialiased(true)
                .resizable()
                .cornerRadius(8)
                .frame(width: 32, height: 32, alignment: .center)
            VStack(alignment: .leading, spacing: 2) {
                Text(archive.name)
                    .font(.system(.body, design: .rounded))
                    .bold()
                Group {
                    Text("\(archive.bundleIdentifier) \(archive.version) \(archive.byteCountDescription)")
                }
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

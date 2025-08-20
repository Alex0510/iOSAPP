import ApplePackage
import Kingfisher
import SwiftUI

// APP预览视图，显示APP的基本信息
struct ArchivePreviewView: View {
    // 要显示的APP归档信息
    let archive: iTunesResponse.iTunesArchive

    var body: some View {
        // 水平排列视图，间距为 8
        HStack(spacing: 8) {
            // 使用 Kingfisher 加载APP图标
            KFImage(URL(string: archive.artworkUrl512 ?? ""))
                .antialiased(true)  // 开启抗锯齿
                .resizable()        // 允许图像调整大小
                .cornerRadius(8)    // 设置圆角半径为 8
                .frame(width: 32, height: 32, alignment: .center)  // 设置图像大小为 32x32
            // 垂直排列文本信息，左对齐，间距为 2
            VStack(alignment: .leading, spacing: 2) {
                // 显示APP名称
                Text(archive.name)
                    .font(.system(.body, design: .rounded))  // 设置字体样式为圆角正文大小
                    .bold()                                 // 字体加粗
                // 将文本内容分组，方便统一设置样式
                Group {
                    // 显示APP包标识符、版本号和字节数描述
                    Text("\(archive.bundleIdentifier) \(archive.version) \(archive.byteCountDescription)")
                }
                .font(.system(.footnote, design: .rounded))  // 设置字体样式为圆角脚注大小
                .foregroundStyle(.secondary)                 // 设置字体颜色为次要颜色
            }
        }
        // 设置水平栈最大宽度为无限大，并左对齐
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

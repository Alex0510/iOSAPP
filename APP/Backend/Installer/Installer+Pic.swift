// 导入 UIKit 框架，用于处理图像和界面相关操作
import UIKit

// 为 Installer 类添加扩展
extension Installer {
    // 创建一个指定边长的白色正方形图像，并返回其 PNG 格式的数据
    // 参数 r: 正方形图像的边长
    // 返回值: 白色正方形图像的 PNG 格式数据
    func createWhite(_ r: CGFloat) -> Data {
        // 创建一个指定大小的图像渲染器
        let renderer = UIGraphicsImageRenderer(size: .init(width: r, height: r))
        // 使用渲染器创建图像
        let image = renderer.image { ctx in
            // 设置填充颜色为白色
            UIColor.white.setFill()
            // 在画布上填充一个指定大小的矩形
            ctx.fill(.init(x: 0, y: 0, width: r, height: r))
        }
        // 将图像转换为 PNG 格式的数据并返回
        return image.pngData()!
    }
}

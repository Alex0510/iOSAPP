import SwiftUI

// 定义一个名为 SimpleProgress 的视图结构体，用于显示简单的进度条
struct SimpleProgress: View {
    // 传入的进度对象
    let progress: Progress
    
    // 计算属性，确保获取到安全的进度值
    private var safeProgress: Double {
        // 获取当前进度的完成比例
        let fraction = progress.fractionCompleted
        // 检查并处理NaN、无穷大或负值
        if fraction.isNaN || fraction.isInfinite || fraction < 0 {
            return 0.0
        }
        // 确保进度值在0到1之间
        return min(max(fraction, 0.0), 1.0)
    }
    
    // 视图主体，定义了进度条的外观
    var body: some View {
        // 创建一个矩形作为进度条的背景
        Rectangle()
            // 设置背景颜色为灰色
            .foregroundStyle(.gray)
            // 在背景矩形上叠加内容
            .overlay {
                // 使用 GeometryReader 获取父视图的尺寸信息
                GeometryReader { r in
                    // 创建一个矩形作为进度条的进度部分
                    Rectangle()
                        // 设置进度部分的颜色为主题色调
                        .foregroundStyle(.tint)
                        // 根据安全进度值计算进度条的宽度
                        .frame(width: CGFloat(safeProgress) * r.size.width)
                        // 最大宽度设置为无穷大，并左对齐
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            // 设置进度条的高度为4
            .frame(height: 4)
            // 将进度条裁剪为圆角矩形，圆角半径为2
            .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}

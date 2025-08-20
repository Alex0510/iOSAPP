import SwiftUI

struct SimpleProgress: View {
    let progress: Progress
    
    private var safeProgress: Double {
        let fraction = progress.fractionCompleted
        // 检查并处理NaN、无穷大或负值
        if fraction.isNaN || fraction.isInfinite || fraction < 0 {
            return 0.0
        }
        // 确保进度值在0到1之间
        return min(max(fraction, 0.0), 1.0)
    }
    
    var body: some View {
        Rectangle()
            .foregroundStyle(.gray)
            .overlay {
                GeometryReader { r in
                    Rectangle()
                        .foregroundStyle(.tint)
                        .frame(width: CGFloat(safeProgress) * r.size.width)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: 4)
            .clipShape(RoundedRectangle(cornerRadius: 2))
    }
}

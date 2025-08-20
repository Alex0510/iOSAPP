import UIKit

extension Installer {
    func createWhite(_ r: CGFloat) -> Data {
        let renderer = UIGraphicsImageRenderer(size: .init(width: r, height: r))
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(.init(x: 0, y: 0, width: r, height: r))
        }
        return image.pngData()!
    }
}

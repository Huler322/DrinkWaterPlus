import SwiftUI

struct GlassShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let topWidth = rect.width * 0.9
        let bottomWidth = rect.width * 0.7
        let height = rect.height
        
        let topLeft = CGPoint(x: (rect.width - topWidth) / 2, y: 0)
        let topRight = CGPoint(x: rect.width - (rect.width - topWidth) / 2, y: 0)
        let bottomRight = CGPoint(x: rect.width - (rect.width - bottomWidth) / 2, y: height)
        let bottomLeft = CGPoint(x: (rect.width - bottomWidth) / 2, y: height)
        
        path.move(to: topLeft)
        path.addQuadCurve(to: bottomLeft, control: CGPoint(x: topLeft.x - 6, y: height / 2))
        path.addLine(to: bottomRight)
        path.addQuadCurve(to: topRight, control: CGPoint(x: topRight.x + 6, y: height / 2))
        path.closeSubpath()
        
        return path
    }
}

import SwiftUI

/// Custom shape for tab bar with a curved hole in the middle
struct TabBarWithHole: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = rect.width / 2
        let holeWidth: CGFloat = 90
        let holeHeight: CGFloat = 35

        path.move(to: CGPoint(x: 0, y: 0))

        path.addLine(to: CGPoint(x: center - (holeWidth / 2) - 15, y: 0))

        path.addCurve(
            to: CGPoint(x: center, y: holeHeight),
            control1: CGPoint(x: center - (holeWidth / 2) + 5, y: 0),
            control2: CGPoint(x: center - (holeWidth / 2) + 10, y: holeHeight)
        )

        path.addCurve(
            to: CGPoint(x: center + (holeWidth / 2) + 15, y: 0),
            control1: CGPoint(x: center + (holeWidth / 2) - 10, y: holeHeight),
            control2: CGPoint(x: center + (holeWidth / 2) - 5, y: 0)
        )

        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
    }
}

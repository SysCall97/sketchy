import SwiftUI

/// Template bounding box - Visual indicator with gesture handling
struct TemplateBoundingBoxView: View {
    let transform: Transform
    let isActive: Bool
    let onDrag: (DragGesture.Value) -> Void
    let onPinch: (MagnificationGesture.Value) -> Void

    @State private var currentScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geometry in
            Rectangle()
                .stroke(isActive ? Color.white.opacity(0.8) : Color.clear, lineWidth: 2)
                .background(Color.clear)
                .frame(width: 300 * transform.scale, height: 400 * transform.scale)
                .offset(
                    x: transform.translation.x,
                    y: transform.translation.y
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            onDrag(value)
                        }
                )
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            currentScale = value
                            onPinch(value)
                        }
                        .onEnded { _ in
                            currentScale = 1.0
                        }
                )
                .overlay(
                    // Corner handles
                    Group {
                        if isActive {
                            cornerHandle(at: .topLeading)
                            cornerHandle(at: .topTrailing)
                            cornerHandle(at: .bottomLeading)
                            cornerHandle(at: .bottomTrailing)
                        }
                    }
                )
        }
    }

    private func cornerHandle(at position: CornerPosition) -> some View {
        Circle()
            .fill(Color.white.opacity(0.9))
            .frame(width: 12, height: 12)
            .offset(handleOffset(for: position))
    }

    private func handleOffset(for position: CornerPosition) -> CGSize {
        let width: CGFloat = 150 * transform.scale
        let height: CGFloat = 200 * transform.scale

        switch position {
        case .topLeading:
            return CGSize(width: -width, height: -height)
        case .topTrailing:
            return CGSize(width: width, height: -height)
        case .bottomLeading:
            return CGSize(width: -width, height: height)
        case .bottomTrailing:
            return CGSize(width: width, height: height)
        }
    }

    enum CornerPosition {
        case topLeading, topTrailing, bottomLeading, bottomTrailing
    }
}

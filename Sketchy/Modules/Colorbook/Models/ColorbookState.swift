import SwiftUI

/// State for colorbook drawing functionality
struct ColorbookState {
    // MARK: - Properties

    /// Currently selected color for filling
    let selectedColor: Color

    /// Current zoom/pan transform of the coloring page
    let pageTransform: Transform

    /// History of fill operations for undo/redo
    let fillHistory: [FillOperation]

    /// Current position in history (for undo/redo)
    let historyIndex: Int

    /// Whether the image is currently being filled
    let isFilling: Bool

    // MARK: - Initial State

    static let initial = ColorbookState(
        selectedColor: .red,
        pageTransform: .identity,
        fillHistory: [],
        historyIndex: -1,
        isFilling: false
    )

    // MARK: - Builder Pattern

    func with(
        selectedColor: Color? = nil,
        pageTransform: Transform? = nil,
        fillHistory: [FillOperation]? = nil,
        historyIndex: Int? = nil,
        isFilling: Bool? = nil
    ) -> ColorbookState {
        ColorbookState(
            selectedColor: selectedColor ?? self.selectedColor,
            pageTransform: pageTransform ?? self.pageTransform,
            fillHistory: fillHistory ?? self.fillHistory,
            historyIndex: historyIndex ?? self.historyIndex,
            isFilling: isFilling ?? self.isFilling
        )
    }
}

// MARK: - Fill Operation

/// Represents a single fill operation for undo/redo
struct FillOperation: Identifiable, Equatable {
    let id = UUID()
    let point: CGPoint
    let color: Color
    let timestamp: Date
    let imageSnapshot: UIImage? // Store the image after this fill operation

    init(point: CGPoint, color: Color, imageSnapshot: UIImage? = nil) {
        self.point = point
        self.color = color
        self.timestamp = Date()
        self.imageSnapshot = imageSnapshot
    }

    static func == (lhs: FillOperation, rhs: FillOperation) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Equatable

extension ColorbookState: Equatable {
    static func == (lhs: ColorbookState, rhs: ColorbookState) -> Bool {
        return lhs.selectedColor.description == rhs.selectedColor.description &&
               lhs.pageTransform == rhs.pageTransform &&
               lhs.fillHistory.count == rhs.fillHistory.count &&
               lhs.historyIndex == rhs.historyIndex &&
               lhs.isFilling == rhs.isFilling
    }
}

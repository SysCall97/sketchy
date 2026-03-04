import Foundation
import SwiftUI
import Combine

/// ViewModel for colorbook drawing functionality
@MainActor
class ColorbookViewModel: ObservableObject {
    @Published var state: ColorbookState

    private let maxHistorySize = 50

    init(initialState: ColorbookState = .initial) {
        self.state = initialState
    }

    // MARK: - Color Management

    /// Update the selected color
    func setColor(_ color: Color) {
        state = state.with(selectedColor: color)
    }

    // MARK: - Fill Operations

    /// Perform a fill operation at the given point
    func fill(at point: CGPoint) {
        let operation = FillOperation(point: point, color: state.selectedColor)

        // If we're not at the end of history, remove future operations
        var newHistory = state.fillHistory
        if state.historyIndex < newHistory.count - 1 {
            newHistory = Array(newHistory.prefix(state.historyIndex + 1))
        }

        // Add new operation
        newHistory.append(operation)

        // Limit history size
        if newHistory.count > maxHistorySize {
            newHistory.removeFirst()
        }

        state = state.with(
            fillHistory: newHistory,
            historyIndex: newHistory.count - 1,
            isFilling: true
        )

        // Reset filling state after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.state = self.state.with(isFilling: false)
        }
    }

    /// Undo the last fill operation
    func undo() {
        guard canUndo() else { return }

        let newIndex = state.historyIndex - 1
        state = state.with(historyIndex: newIndex)
    }

    /// Redo the previously undone fill operation
    func redo() {
        guard canRedo() else { return }

        let newIndex = state.historyIndex + 1
        state = state.with(historyIndex: newIndex)
    }

    // MARK: - State Queries

    /// Check if undo is available
    func canUndo() -> Bool {
        state.historyIndex >= 0
    }

    /// Check if redo is available
    func canRedo() -> Bool {
        state.historyIndex < state.fillHistory.count - 1
    }

    // MARK: - Transform Management

    /// Update the page transform
    func updatePageTransform(_ transform: Transform) {
        state = state.with(pageTransform: transform)
    }

    /// Reset the transform to identity
    func resetTransform() {
        state = state.with(pageTransform: .identity)
    }
}

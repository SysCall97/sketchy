import Foundation
import SwiftUI
import Combine
import UIKit

/// ViewModel for colorbook drawing functionality
@MainActor
class ColorbookViewModel: ObservableObject {
    @Published var state: ColorbookState
    @Published var currentImage: UIImage? // Track current image state

    private let maxHistorySize = 50

    init(initialState: ColorbookState = .initial) {
        self.state = initialState
        self.currentImage = nil
    }

    // MARK: - Color Management

    /// Update the selected color
    func setColor(_ color: Color) {
        state = state.with(selectedColor: color)
    }

    // MARK: - Fill Operations

    /// Initialize the history with the original image
    func initializeImage(_ image: UIImage) {
        // Only initialize if history is empty
        guard state.fillHistory.isEmpty else {
            currentImage = image
            return
        }

        // Create initial operation with original image
        let initialOperation = FillOperation(point: .zero, color: .clear, imageSnapshot: image)

        // Update state and current image
        currentImage = image
        state = state.with(
            fillHistory: [initialOperation],
            historyIndex: 0
        )
    }

    /// Perform a fill operation with the resulting image
    func recordFill(at point: CGPoint, filledImage: UIImage) {
        let operation = FillOperation(point: point, color: state.selectedColor, imageSnapshot: filledImage)

        // If we're not at the end of history, remove future operations
        var newHistory = state.fillHistory
        if state.historyIndex < newHistory.count - 1 {
            newHistory = Array(newHistory.prefix(state.historyIndex + 1))
        }

        // Add new operation with image snapshot
        newHistory.append(operation)

        // Limit history size
        if newHistory.count > maxHistorySize {
            newHistory.removeFirst()
        }

        // Update state and current image
        currentImage = filledImage
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
        guard canUndo(), state.historyIndex > 0 else { return }

        let newIndex = state.historyIndex - 1
        let previousImage = state.fillHistory[newIndex].imageSnapshot

        currentImage = previousImage
        state = state.with(historyIndex: newIndex)
    }

    /// Redo the previously undone fill operation
    func redo() {
        guard canRedo() else { return }

        let newIndex = state.historyIndex + 1
        let nextImage = state.fillHistory[newIndex].imageSnapshot

        currentImage = nextImage
        state = state.with(historyIndex: newIndex)
    }

    /// Get the image for the current history index
    func getImageAtCurrentIndex() -> UIImage? {
        guard state.historyIndex >= 0, state.historyIndex < state.fillHistory.count else { return nil }
        return state.fillHistory[state.historyIndex].imageSnapshot
    }

    // MARK: - State Queries

    /// Check if undo is available
    func canUndo() -> Bool {
        state.historyIndex > 0
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

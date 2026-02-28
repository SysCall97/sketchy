import Foundation
import SwiftUI
import Combine

@MainActor
class ModeSelectionViewModel: ObservableObject {
    @Published var selectedMode: ModeSelectionState.DrawingMode = .abovePaper
    let template: TemplateModel

    init(template: TemplateModel) {
        self.template = template
    }

    func confirmSelection() -> DrawingState.DrawingMode {
        selectedMode.toDrawingMode
    }
}

import SwiftUI
import Combine

/// Protocol defining the coordinator contract for navigation
protocol Coordinatable: ObservableObject {
    var rootView: AnyView { get }

    /// Start the coordinator's flow
    func start()
}

/// Navigation routes available in the app
enum CoordinatorRoute: Hashable {
    case home
    case modeSelection(template: TemplateModel)
    case drawing(template: TemplateModel, mode: DrawingState.DrawingMode)
    case templateGallery
}

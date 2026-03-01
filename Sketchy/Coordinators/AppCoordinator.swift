import SwiftUI
import Combine

/// Root coordinator that manages app-wide navigation and flow
@MainActor
class AppCoordinator: Coordinatable {
    // Navigation path for proper push/pop animations
    @Published var navigationPath = NavigationPath()

    // Pending project state for loading saved projects
    @Published var pendingProjectState: DrawingState?

    // MARK: - Services

    let subscriptionManager = SubscriptionManager()

    var rootView: AnyView {
        AnyView(HomeView(coordinator: self))
    }

    // MARK: - Navigation

    /// Navigate to a specific route
    func navigate(to route: CoordinatorRoute) {
        navigationPath.append(route)
    }

    /// Navigate to home screen
    func goToHome() {
        navigationPath.removeLast(navigationPath.count)
    }

    /// Navigate to drawing screen with a template (routes through mode selection)
    func goToDrawing(with template: TemplateModel) {
        navigate(to: .modeSelection(template: template))
    }

    /// Navigate to mode selection screen with a template
    func goToModeSelection(with template: TemplateModel) {
        navigate(to: .modeSelection(template: template))
    }

    /// Navigate to drawing screen with a template and mode
    func goToDrawing(with template: TemplateModel, mode: DrawingState.DrawingMode) {
        pendingProjectState = nil
        navigate(to: .drawing(template: template, mode: mode))
    }

    /// Navigate to drawing screen with a template and initial state (for loading projects)
    func goToDrawing(with template: TemplateModel, initialState: DrawingState) {
        pendingProjectState = initialState
        navigate(to: .drawing(template: template, mode: initialState.mode))
    }

    /// Navigate to template gallery
    func goToTemplateGallery() {
        navigate(to: .templateGallery)
    }

    /// Go back to previous screen
    func goBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
        pendingProjectState = nil
    }

    // MARK: - Coordinator Lifecycle

    func start() {
        // Initialize app-level services
        setupServices()
    }

    private func setupServices() {
        // Initialize SubscriptionManager with product IDs
        // TODO: Add your product IDs from App Store Connect
        let productIds = [
            "com.sketchy.subscription.weekly"
        ]
        let subscriptionGroupId = "21338383" // TODO: Add your subscription group ID from App Store Connect

        subscriptionManager.initWithProductIDS(
            productIds: productIds,
            subscriptionGroupId: subscriptionGroupId
        )
    }
}

import SwiftUI
import Combine

/// Root coordinator that manages app-wide navigation and flow
@MainActor
class AppCoordinator: Coordinatable {
    @Published var currentRoute: CoordinatorRoute = .home

    // MARK: - Services

    let subscriptionManager = SubscriptionManager()

    var rootView: AnyView {
        switch currentRoute {
        case .home:
            return AnyView(HomeView(coordinator: self))
        case .drawing(let template):
            return AnyView(DrawingView(coordinator: self, template: template))
        case .templateGallery:
            return AnyView(TemplateGalleryView(coordinator: self))
        }
    }

    // MARK: - Navigation

    /// Navigate to a specific route
    func navigate(to route: CoordinatorRoute) {
        currentRoute = route
    }

    /// Navigate to home screen
    func goToHome() {
        navigate(to: .home)
    }

    /// Navigate to drawing screen with a template
    func goToDrawing(with template: TemplateModel) {
        navigate(to: .drawing(template: template))
    }

    /// Navigate to template gallery
    func goToTemplateGallery() {
        navigate(to: .templateGallery)
    }

    /// Go back to previous screen
    func goBack() {
        switch currentRoute {
        case .drawing, .templateGallery:
            goToHome()
        case .home:
            break  // Already at home
        }
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

import SwiftUI
import Combine

/// Root coordinator that manages app-wide navigation and flow
@MainActor
class AppCoordinator: Coordinatable {
    // Navigation path for proper push/pop animations
    @Published var navigationPath = NavigationPath()

    // Splash screen state
    @Published var showSplash = true

    // Pending project state for loading saved projects
    @Published var pendingProjectState: DrawingState?

    // MARK: - Services

    let subscriptionManager = SubscriptionManager()
    let onboardingManager = OnboardingManager.shared

    var rootView: AnyView {
        AnyView(
            Group {
                if showSplash {
                    SplashView(coordinator: self)
                } else if !onboardingManager.hasCompletedOnboarding() {
                    WelcomeView(coordinator: self)
                } else {
                    HomeView(coordinator: self)
                }
            }
        )
    }

    // MARK: - Navigation

    /// Navigate to a specific route
    func navigate(to route: CoordinatorRoute) {
        navigationPath.append(route)
    }

    /// Complete splash screen and navigate to appropriate screen
    func completeSplash() {
        // Check if onboarding is completed
        if onboardingManager.hasCompletedOnboarding() {
            // Push home view with navigation animation
            navigate(to: .home)
        } else {
            // Push welcome view with navigation animation
            navigate(to: .welcome)
        }

        // After push completes, clear path and switch root
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.navigationPath = NavigationPath()
            self.showSplash = false
        }
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

    /// Navigate to colorbook gallery
    func goToColorbook() {
        navigate(to: .colorbook)
    }

    /// Navigate to colorbook drawing screen with a coloring page
    func goToColorbookDrawing(with coloringPage: TemplateModel) {
        navigate(to: .colorbookDrawing(coloringPage: coloringPage))
    }

    // MARK: - Onboarding Navigation

    /// Navigate to welcome screen
    func goToWelcome() {
        navigate(to: .welcome)
    }

    /// Navigate to tutorial screen
    func goToTutorial() {
        navigate(to: .tutorial)
    }

    /// Navigate to final onboarding screen
    func goToFinalOnboarding() {
        navigate(to: .finalOnboarding)
    }

    /// Complete onboarding and navigate to home
    func completeOnboarding() {
        // Mark onboarding as complete first
        onboardingManager.markOnboardingCompleted()

        // Push home view with navigation animation (right to left)
        navigate(to: .home)

        // After push completes, clear path so root view shows HomeView
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            self.navigationPath = NavigationPath()
//        }
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

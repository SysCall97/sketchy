import SwiftUI

/// Splash screen with drawing layers animation
struct SplashView: View {
    @ObservedObject var coordinator: AppCoordinator

    var body: some View {
        ZStack {
            // Drawing layers animation
            DrawingLayersAnimation {
                coordinator.completeSplash()
            }
            .frame(width: 260, height: 260)
        }
    }
}

/// Preview
#Preview {
    SplashView(coordinator: AppCoordinator())
}

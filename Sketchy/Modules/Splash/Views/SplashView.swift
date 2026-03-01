import SwiftUI

/// Splash screen with drawing layers animation
struct SplashView: View {
    let onComplete: () -> Void

    var body: some View {
        ZStack {
            // Drawing layers animation
            DrawingLayersAnimation {
                onComplete()
            }
            .frame(width: 260, height: 260)
        }
    }
}

/// Preview
#Preview {
    SplashView {
        print("Splash complete")
    }
}

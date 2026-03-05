//
//  PromoFloatingButton.swift
//  Sketchy
//
//  Created by Claude Code
//

import SwiftUI
import Combine

/// Floating promotional button with 24-hour countdown timer
struct PromoFloatingButton: View {
    // MARK: - State
    @State private var remainingTime: TimeInterval = 0
    @State private var isAnimating = false
    @State private var floatOffset: CGFloat = 0
    @State private var timerCancellable: AnyCancellable? = nil
    @State private var appLaunchDate: Date?
    @State private var hasLoadedDate = false

    // MARK: - Bindings
    @Binding var isPaywallPresented: Bool

    // MARK: - Dependencies
    private let keychainManager = KeychainManager.shared
    private let timeInterval: TimeInterval = 24 * 60 * 60 // 24 hours in seconds

    // MARK: - Computed Properties
    private var shouldShowButton: Bool {
        // Always show initially until we load the actual date
        guard let launchDate = appLaunchDate else { return true }
        let hoursPassed = Date().timeIntervalSince(launchDate) / 3600
        return hoursPassed < 24
    }

    private var timeRemainingString: String {
        // Use remainingTime state to trigger view updates
        let remaining = remainingTime

        let hours = Int(remaining) / 3600
        let minutes = Int(remaining) % 3600 / 60
        let seconds = Int(remaining) % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // MARK: - Body
    var body: some View {
        if shouldShowButton {
            Button(action: {
                isPaywallPresented = true
            }) {
                VStack(spacing: 0) {
                    // Animated icon container
                    ZStack {
                        // Cat card (bottom layer) - smaller scale from animation
                        Image("mascot_1")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 45, height: 45)
                            .shadow(radius: 2)

                        // Pencil (top layer) - with angle and offset from animation, smaller scale
//                        Image("pencil")
//                            .resizable()
//                            .scaledToFit()
//                            .frame(width: 25, height: 25)
//                            .rotationEffect(.degrees(10))
//                            .offset(x: 12, y: 0)
//                            .shadow(radius: 1)
                    }
                    .frame(width: 60, height: 60)
//                    .background(
//                        Circle()
//                            .fill(
//                                LinearGradient(
//                                    gradient: Gradient(colors: [Color.blue.opacity(0.85), Color.purple.opacity(0.85)]),
//                                    startPoint: .topLeading,
//                                    endPoint: .bottomTrailing
//                                )
//                            )
//                            .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 5)
//                    )
                    .scaleEffect(isAnimating ? 1.08 : 1.0)
                    .offset(y: floatOffset)

                    Text(timeRemainingString)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.7))
                                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                        )
                }
            }
            .buttonStyle(PlainButtonStyle())
            .task {
                // Load launch date only once
                if !hasLoadedDate {
                    appLaunchDate = keychainManager.getAppLaunchDate()
                    hasLoadedDate = true
                }
                updateRemainingTime()
                startAnimations()
                startTimer()
            }
            .onDisappear {
                timerCancellable?.cancel()
            }
        }
    }

    // MARK: - Helper Methods

    private func updateRemainingTime() {
        guard let launchDate = appLaunchDate else { return }
        let elapsed = Date().timeIntervalSince(launchDate)
        remainingTime = max(0, timeInterval - elapsed)
    }

    // MARK: - Animation
    private func startAnimations() {
        withAnimation(
            Animation.easeInOut(duration: 1.8)
                .repeatForever(autoreverses: true)
        ) {
            isAnimating = true
        }

        withAnimation(
            Animation.easeInOut(duration: 2.2)
                .repeatForever(autoreverses: true)
        ) {
            floatOffset = -10
        }
    }

    // MARK: - Timer
    private func startTimer() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                updateRemainingTime()
            }
    }
}

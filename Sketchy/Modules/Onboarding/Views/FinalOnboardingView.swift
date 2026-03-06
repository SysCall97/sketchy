//
//  FinalOnboardingView.swift
//  Sketchy
//
//  Created by Kazi Mashry on 5/3/26.
//

import SwiftUI

// MARK: - Final Onboarding View

struct FinalOnboardingView: View {
    // MARK: - Dependencies
    @ObservedObject var coordinator: AppCoordinator

    // MARK: - State
    @State private var isMascotAnimated = false
    @State private var isButtonVisible = false

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            // Top Section - Mascot Illustration
            Spacer()

            Image("mascot_1")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
                .offset(y: isMascotAnimated ? -7 : 0)
                .animation(
                    Animation.easeInOut(duration: 2.7)
                        .repeatForever(autoreverses: true),
                    value: isMascotAnimated
                )

            Spacer()
                .frame(height: 60)

            // Center Text Section
            VStack(spacing: 12) {
                // Headline
                Text("You're ready to draw.")
                    .font(.system(size: 30, weight: .semibold))
                    .foregroundColor(Color(red: 0.11, green: 0.11, blue: 0.11))
                    .multilineTextAlignment(.center)

                // Supporting Text
                Text("Grab a pencil and start your first sketch.\nYou get one free drawing every day.")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(Color(red: 0.42, green: 0.42, blue: 0.42))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, 32)

            Spacer()

            // Bottom Section - Primary Button
            Button(action: {
                HapticGenerator.triggerImpactHaptic(style: .light)
                coordinator.completeOnboarding()
            }) {
                Text("Start Drawing")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
            }
            .padding(.horizontal, 28)
            .opacity(isButtonVisible ? 1 : 0)
            .offset(y: isButtonVisible ? 0 : 20)
            .animation(
                Animation.easeOut(duration: 0.45).delay(0.35),
                value: isButtonVisible
            )
            .padding(.bottom, 40)
        }
        .onAppear {
            // Start mascot animation
            isMascotAnimated = true

            // Trigger button entrance animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.easeOut(duration: 0.45)) {
                    isButtonVisible = true
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Preview

#Preview {
    FinalOnboardingView(coordinator: AppCoordinator())
}

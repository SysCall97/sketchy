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

    // MARK: - Body
    var body: some View {
        VStack {
            Button("Complete Onboarding") {
                coordinator.completeOnboarding()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Preview

#Preview {
    FinalOnboardingView(coordinator: AppCoordinator())
}

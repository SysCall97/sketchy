//
//  TutorialView.swift
//  Sketchy
//
//  Created by Kazi Mashry on 5/3/26.
//

import SwiftUI

// MARK: - Tutorial View

struct TutorialView: View {
    // MARK: - Dependencies
    @ObservedObject var coordinator: AppCoordinator

    // MARK: - Body
    var body: some View {
        VStack {
            Button("Skip") {
                coordinator.goToFinalOnboarding()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Preview

#Preview {
    TutorialView(coordinator: AppCoordinator())
}

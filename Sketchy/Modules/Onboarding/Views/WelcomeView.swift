//
//  WelcomeView.swift
//  Sketchy
//
//  Created by Kazi Mashry on 5/3/26.
//

import SwiftUI

// MARK: - Welcome View

struct WelcomeView: View {
    // MARK: - Dependencies
    @ObservedObject var coordinator: AppCoordinator

    // MARK: - Body
    var body: some View {
        VStack {
            Button("Go to Tutorial") {
                coordinator.goToTutorial()
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Preview

#Preview {
    WelcomeView(coordinator: AppCoordinator())
}

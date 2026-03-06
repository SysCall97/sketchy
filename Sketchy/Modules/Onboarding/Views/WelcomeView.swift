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

    // MARK: - State
    // Quote is pre-selected when app launches, not when view appears
    @State private var quote: Quote?

    // MARK: - Initializer
    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        // Use pre-selected quote from app launch
        self._quote = State(initialValue: QuoteManager.shared.getRandomQuote())
    }

    // MARK: - Body
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // App Icon
            Image(.appIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .clipShape(RoundedCorner(radius: 25))

            Spacer()
                .frame(height: 60)

            // Quote Section
            if let quote = quote {
                VStack(spacing: 12) {
                    // Quote with quotation marks, bold and italic
                    Text("\"\(quote.quote)\"")
                        .font(.system(.title3, design: .monospaced))
                        .fontWeight(.bold)
                        .italic()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    // Author name in gray
                    Text("— \(quote.author)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Get Started Button
            Button(action: {
                HapticGenerator.triggerImpactHaptic(style: .light)
                coordinator.goToTutorial()
            }) {
                Text("Get Started")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Preview

#Preview {
    WelcomeView(coordinator: AppCoordinator())
}


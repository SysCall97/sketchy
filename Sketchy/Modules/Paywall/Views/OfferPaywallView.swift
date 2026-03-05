//
//  OfferPaywallView.swift
//  Sketchy
//
//  Created by Claude Code
//

import SwiftUI
import Combine

/// Special offer paywall with 24-hour countdown for early supporters
struct OfferPaywallView: View {
    // MARK: - Bindings
    @Binding var isPresented: Bool
    @ObservedObject var subscriptionManager: SubscriptionManager

    // MARK: - State
    @State private var remainingTime: TimeInterval = 0
    @State private var timerCancellable: AnyCancellable? = nil
    @State private var appLaunchDate: Date?
    @State private var hasLoadedDate = false

    // MARK: - Dependencies
    private let keychainManager = KeychainManager.shared
    private let timeInterval: TimeInterval = 24 * 60 * 60 // 24 hours in seconds
    let productID: String = "com.sketchy.subscription.yearly" // Yearly subscription for $25

    // MARK: - Computed Properties
    private var timeRemainingString: String {
        let remaining = remainingTime
        let hours = Int(remaining) / 3600
        let minutes = Int(remaining) % 3600 / 60
        let seconds = Int(remaining) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // MARK: - App Icon & Name (same as main paywall)
                    VStack(spacing: 6) {
                        Image(.mascot1)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .shadow(radius: 4)

                        Text("Sketchy")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 8)

                    // MARK: - Top Small Label
                    Text("Early Supporter Offer")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(16)

                    // MARK: - Main Headline
                    Text("Unlock Sketchy")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    // MARK: - Subheadline
                    Text("Offer ends in")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    // MARK: - Countdown Container
                    Text("\(timeRemainingString)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)

                    // MARK: - Feature Section
                    VStack(alignment: .leading, spacing: 12) {
                        BenefitRow(icon: "checkmark.circle.fill", title: "Unlimited drawings every day")
                        BenefitRow(icon: "checkmark.circle.fill", title: "Unlimited project savings every day")
                        BenefitRow(icon: "checkmark.circle.fill", title: "This app will always be ad free")
                        BenefitRow(icon: "checkmark.circle.fill", title: "Support indie dev for future improvements")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)

                    // MARK: - Emotional Support Line
                    VStack(spacing: 4) {
                        Text("Sketchy is built independently.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Your support helps me keep improving it.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // MARK: - Loader overlay
                    if subscriptionManager.loaderStatus != .none && subscriptionManager.loaderStatus != .dismiss {
                        VStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())

                            Text(subscriptionManager.loaderStatus.status)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 4)
                    }

                    // MARK: - Primary Button
                    Button(action: {
                        handleSubscribe()
                    }) {
                        Text("Become an Early Supporter")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue, Color.purple]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    .disabled(subscriptionManager.loaderStatus != .none && subscriptionManager.loaderStatus != .dismiss)

                    // MARK: - Footer
                    VStack(spacing: 8) {
                        Text("$25/year. Auto-renewing. Cancel anytime.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)

                        // Restore & Links
                        VStack(spacing: 6) {
                            Button(action: {
                                handleRestore()
                            }) {
                                Text("Restore Purchases")
                                    .font(.caption2)
                                    .foregroundColor(.blue)
                            }

                            HStack(spacing: 12) {
                                Button("Terms") {
                                    // TODO: Open terms of use
                                }
                                .font(.caption2)
                                .foregroundColor(.gray)

                                Text("•")
                                    .font(.caption2)
                                    .foregroundColor(.gray)

                                Button("Privacy") {
                                    // TODO: Open privacy policy
                                }
                                .font(.caption2)
                                .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 12)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        isPresented = false
                    }
                }
            }
        }
        .task {
            loadLaunchDate()
            startTimer()
        }
        .onDisappear {
            timerCancellable?.cancel()
        }
        .onChange(of: subscriptionManager.currentPurchaseState) { newState in
            if subscriptionManager.isSubscribedOrUnlockedAll() {
                dismissPaywall()
            }
        }
    }

    // MARK: - Helper Methods

    private func loadLaunchDate() {
        guard !hasLoadedDate else { return }
        appLaunchDate = keychainManager.getAppLaunchDate()
        hasLoadedDate = true
        updateRemainingTime()
    }

    private func updateRemainingTime() {
        guard let launchDate = appLaunchDate else { return }
        let elapsed = Date().timeIntervalSince(launchDate)
        remainingTime = max(0, timeInterval - elapsed)
    }

    private func startTimer() {
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                updateRemainingTime()
            }
    }

    private func dismissPaywall() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPresented = false
        }
    }

    private func handleSubscribe() {
        subscriptionManager.purchaseRequest(productID: productID)
    }

    private func handleRestore() {
        subscriptionManager.restorePurchase()
    }
}

#Preview {
    StatefulPreviewWrapper()
}

private struct StatefulPreviewWrapper: View {
    @State private var isPresented = true
    @StateObject var subscriptionManager = SubscriptionManager()

    var body: some View {
        OfferPaywallView(
            isPresented: $isPresented,
            subscriptionManager: subscriptionManager
        )
    }
}

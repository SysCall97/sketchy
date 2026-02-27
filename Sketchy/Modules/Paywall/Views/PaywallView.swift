import SwiftUI

/// Paywall screen for subscription upgrade
struct PaywallView: View {
    @Binding var isPresented: Bool
    let subscriptionManager: SubscriptionManager
    let productID: String

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    // App Icon & Name
                    VStack(spacing: 8) {
                        Image(systemName: "pencil.and.outline")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)

                        Text("Sketchy")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    .padding(.top, 12)

                    // Value-driven headline
                    VStack(spacing: 6) {
                        Text("Enjoying your drawing?")
                            .font(.title3)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("You get one free drawing per day to try Sketchy. Unlock unlimited drawings and support independent development.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Benefits List
                    VStack(alignment: .leading, spacing: 12) {
                        BenefitRow(icon: "infinity", title: "Unlimited drawings every day")
                        BenefitRow(icon: "photo.on.rectangle.angled", title: "Full access to all templates")
                        BenefitRow(icon: "camera", title: "Both camera & lightbox modes")
                        BenefitRow(icon: "sparkles", title: "All future features included")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)

                    // Pricing Disclosure (Apple Requirement)
                    VStack(spacing: 6) {
                        Text("$0.99 for the first week, then $3.99 per week.")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Text("Auto-renewing subscription. Cancel anytime.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)

                    // Loader overlay
                    if subscriptionManager.loaderStatus != .none && subscriptionManager.loaderStatus != .dismiss {
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())

                            Text(subscriptionManager.loaderStatus.status)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 4)
                    }

                    // Primary CTA Button
                    Button(action: {
                        handleSubscribe()
                    }) {
                        Text("Start $0.99 Week")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(subscriptionManager.loaderStatus == .none ? Color.blue : Color.gray)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .disabled(subscriptionManager.loaderStatus != .none && subscriptionManager.loaderStatus != .dismiss)

                    // Restore Purchases Button
                    Button(action: {
                        handleRestore()
                    }) {
                        Text("Restore Purchases")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 4)

                    // Footer Links
                    HStack(spacing: 16) {
                        Button("Privacy Policy") {
                            // TODO: Open privacy policy
                        }
                        .font(.caption)

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Button("Terms of Use") {
                            // TODO: Open terms of use
                        }
                            .font(.caption)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    .foregroundColor(.gray)
                }
                .padding(.horizontal)
                .padding(.top, 12)
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
    }

    private func handleSubscribe() {
        subscriptionManager.purchaseRequest(productID: productID)
    }

    private func handleRestore() {
        subscriptionManager.restorePurchase()
    }
}

/// Benefit row component
struct BenefitRow: View {
    let icon: String
    let title: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.blue)
                .frame(width: 26)

            Text(title)
                .font(.subheadline)
        }
    }
}

#Preview {
    PaywallView(
        isPresented: .constant(true),
        subscriptionManager: SubscriptionManager(),
        productID: "com.sketchy.subscription.weekly"
    )
}

import SwiftUI

/// Indicator showing daily free drawing availability
struct DailyLimitIndicator: View {
    @ObservedObject var limitManager: DailyLimitManager
    let subscriptionManager: SubscriptionManager
    var onTapUpgrade: (() -> Void)?

    var body: some View {
        // Only show if not subscribed
        if !subscriptionManager.isSubscribedOrUnlockedAll() && limitManager.shouldShowDailyLimitIndicator() {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(availableColor.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(availableColor)
                }

                // Status Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(statusTitle)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(statusSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Upgrade button (only shown when limit reached)
                if !limitManager.hasFreeDrawingAvailable {
                    Button(action: {
                        onTapUpgrade?()
                    }) {
                        Text("Upgrade")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(availableColor.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(availableColor.opacity(0.2), lineWidth: 1)
            )
        }
    }

    // MARK: - Computed Properties

    private var availableColor: Color {
        limitManager.hasFreeDrawingAvailable ? .green : .orange
    }

    private var icon: String {
        limitManager.hasFreeDrawingAvailable ? "checkmark.circle.fill" : "clock.fill"
    }

    private var statusTitle: String {
        if limitManager.hasFreeDrawingAvailable {
            let remaining = limitManager.freeDrawingsRemaining()
            return remaining == 1 ? "1 free drawing available" : "\(remaining) free drawings available"
        } else {
            return "Daily limit reached"
        }
    }

    private var statusSubtitle: String {
        if limitManager.hasFreeDrawingAvailable {
            return "Start drawing now"
        } else {
            return "Resets in \(limitManager.timeUntilResetString())"
        }
    }
}

#Preview {
    // Reset to a clean state for preview
    UserDefaults.standard.set(0, forKey: "com.sketchy.drawingsUsedToday")
    UserDefaults.standard.set(Date(), forKey: "com.sketchy.lastResetDate")

    return DailyLimitIndicator(
        limitManager: DailyLimitManager.shared,
        subscriptionManager: SubscriptionManager(),
        onTapUpgrade: {
            print("Upgrade tapped")
        }
    )
    .padding()
    .background(Color.gray.opacity(0.1))
}

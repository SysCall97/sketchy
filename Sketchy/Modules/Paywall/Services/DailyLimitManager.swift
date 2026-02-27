import Foundation
import Combine

/// Manages daily drawing limits for free users
@MainActor
class DailyLimitManager: ObservableObject {

    // MARK: - Shared Instance

    static let shared = DailyLimitManager()

    // MARK: - Published Properties

    @Published var hasFreeDrawingAvailable: Bool = true
    @Published var timeUntilReset: TimeInterval = 0

    // MARK: - Constants

    private let freeDrawingsPerDay = 1
    private let resetWindow: TimeInterval = 20//24 * 60 * 60 // 24 hours in seconds
    private let timerInterval: TimeInterval = 1.0 // Update every second

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let lastDrawingDate = "com.sketchy.lastDrawingDate"
        static let drawingsUsedToday = "com.sketchy.drawingsUsedToday"
        static let lastResetDate = "com.sketchy.lastResetDate"
    }

    // MARK: - Timer

    private var timer: Timer?

    // MARK: - Initialization

    private init() {
        checkAndResetIfNeeded()
        updateAvailability()
        startTimer()
    }

    // MARK: - Timer Control

    private func startTimer() {
        // Update time immediately
        updateTimeUntilReset()

        // Start timer to update every second
        timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateTimeUntilReset()
            }
        }
    }

    private func updateTimeUntilReset() {
        let defaults = UserDefaults.standard

        guard let lastReset = defaults.object(forKey: Keys.lastResetDate) as? Date else {
            return
        }

        let timeSinceReset = Date().timeIntervalSince(lastReset)
        let remaining = resetWindow - timeSinceReset

        // Check if reset is needed
        if remaining <= 0 {
            resetDailyCounter()
        } else {
            timeUntilReset = remaining
        }
    }

    // MARK: - Public Methods

    /// Checks if user can start a new drawing session
    func canStartDrawing() -> Bool {
        checkAndResetIfNeeded()
        updateAvailability()
        return hasFreeDrawingAvailable
    }

    /// Records a completed drawing session (regardless of whether it was saved or abandoned)
    func recordDrawingSession() {
        let defaults = UserDefaults.standard

        // Get current usage
        var usedCount = defaults.integer(forKey: Keys.drawingsUsedToday)

        // Increment usage
        usedCount += 1
        defaults.set(usedCount, forKey: Keys.drawingsUsedToday)

        // Update last drawing date
        defaults.set(Date(), forKey: Keys.lastDrawingDate)

        // Update availability
        updateAvailability()
    }

    /// Returns the time until the next reset as a formatted string (hh:mm:ss)
    func timeUntilResetString() -> String {
        let timeInterval = timeUntilReset

        if timeInterval <= 0 {
            return "00:00:00"
        }

        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        let seconds = Int(timeInterval) % 60

        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    /// Returns the count of free drawings used today
    func drawingsUsedTodayCount() -> Int {
        return UserDefaults.standard.integer(forKey: Keys.drawingsUsedToday)
    }

    /// Returns the count of free drawings remaining today
    func freeDrawingsRemaining() -> Int {
        return max(0, freeDrawingsPerDay - drawingsUsedTodayCount())
    }

    // MARK: - Private Methods

    private func checkAndResetIfNeeded() {
        let defaults = UserDefaults.standard

        // Get last reset date
        if let lastReset = defaults.object(forKey: Keys.lastResetDate) as? Date {
            let timeSinceReset = Date().timeIntervalSince(lastReset)

            // If 24 hours have passed, reset the counter
            if timeSinceReset >= resetWindow {
                resetDailyCounter()
            } else {
                // Update time until reset
                timeUntilReset = resetWindow - timeSinceReset
            }
        } else {
            // First time using the app, set the reset date
            defaults.set(Date(), forKey: Keys.lastResetDate)
            timeUntilReset = resetWindow
        }
    }

    private func resetDailyCounter() {
        let defaults = UserDefaults.standard

        // Reset counter
        defaults.set(0, forKey: Keys.drawingsUsedToday)
        defaults.set(Date(), forKey: Keys.lastResetDate)

        // Reset time
        timeUntilReset = resetWindow

        // Update availability to trigger view refresh
        updateAvailability()

        print("DailyLimitManager: Counter reset")
    }

    private func updateAvailability() {
        let usedCount = UserDefaults.standard.integer(forKey: Keys.drawingsUsedToday)
        hasFreeDrawingAvailable = usedCount < freeDrawingsPerDay
        if hasFreeDrawingAvailable {
            startTimer()
        }
    }
}

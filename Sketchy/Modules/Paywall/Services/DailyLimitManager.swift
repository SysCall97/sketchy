import Foundation
import Combine

/// Manages daily drawing limits for free users
/// Uses Keychain for storage to persist across app installations
@MainActor
class DailyLimitManager: ObservableObject {

    // MARK: - Shared Instance

    static let shared = DailyLimitManager()

    // MARK: - Published Properties

    @Published var hasFreeDrawingAvailable: Bool = true
    @Published var timeUntilReset: TimeInterval = 0

    // MARK: - Session State

    // Tracks if the indicator has been shown this session (resets to false on app launch)
    private(set) var hasShownIndicatorThisSession = false {
        didSet {
            objectWillChange.send()
        }
    }

    // MARK: - Constants

    private let freeDrawingsPerDay = 1
    private let resetWindow: TimeInterval = 24 * 60 * 60
    private let timerInterval: TimeInterval = 1.0

    // MARK: - Dependencies

    private let keychain = KeychainManager.shared

    // MARK: - Cached Data (for performance)

    private var cachedData: KeychainManager.DailyLimitData?

    // MARK: - Timer

    private var timer: Timer?

    // MARK: - Initialization

    private init() {
        loadDataFromKeychain()
        checkAndResetIfNeeded()
        updateAvailability()
        startTimer()
    }

    // MARK: - Timer Control

    private func startTimer() {
        updateTimeUntilReset()

        timer = Timer.scheduledTimer(withTimeInterval: timerInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateTimeUntilReset()
            }
        }
    }

    private func updateTimeUntilReset() {
        guard let lastReset = cachedData?.lastResetDate else {
            return
        }

        let timeSinceReset = Date().timeIntervalSince(lastReset)
        let remaining = resetWindow - timeSinceReset

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
        loadDataFromKeychain()

        let usedCount = cachedData?.drawingsUsedToday ?? 0
        let newCount = usedCount + 1
        let now = Date()

        var lastReset = cachedData?.lastResetDate

        // If this was the last free drawing (limit reached), start the countdown from now
        if newCount >= freeDrawingsPerDay {
            lastReset = now
            timeUntilReset = resetWindow
        }

        // Create updated data
        let newData = KeychainManager.DailyLimitData(
            lastDrawingDate: now,
            drawingsUsedToday: newCount,
            lastResetDate: lastReset ?? now,
            deviceIdentifier: keychain.getDeviceIdentifier()
        )

        saveDataToKeychain(newData)
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
        loadDataFromKeychain()
        return cachedData?.drawingsUsedToday ?? 0
    }

    /// Returns the count of free drawings remaining today
    func freeDrawingsRemaining() -> Int {
        return max(0, freeDrawingsPerDay - drawingsUsedTodayCount())
    }

    /// Returns whether the daily limit indicator should be shown
    func shouldShowDailyLimitIndicator() -> Bool {
        if !hasFreeDrawingAvailable {
            return true
        }
        return hasShownIndicatorThisSession
    }

    // MARK: - Keychain Operations

    private func loadDataFromKeychain() {
        cachedData = keychain.loadDailyLimitData()

        // If no data exists, create initial data
        if cachedData == nil {
            let deviceIdentifier = keychain.getDeviceIdentifier()
            let initialData = KeychainManager.DailyLimitData(
                lastDrawingDate: nil,
                drawingsUsedToday: 0,
                lastResetDate: Date(),
                deviceIdentifier: deviceIdentifier
            )
            saveDataToKeychain(initialData)
        }
    }

    private func saveDataToKeychain(_ data: KeychainManager.DailyLimitData) {
        cachedData = data
        keychain.saveDailyLimitData(data)
    }

    // MARK: - Private Methods

    private func checkAndResetIfNeeded() {
        loadDataFromKeychain()

        guard let lastReset = cachedData?.lastResetDate else {
            return
        }

        let timeSinceReset = Date().timeIntervalSince(lastReset)

        if timeSinceReset >= resetWindow {
            resetDailyCounter()
        } else {
            timeUntilReset = resetWindow - timeSinceReset
        }
    }

    private func resetDailyCounter() {
        let now = Date()
        let resetData = KeychainManager.DailyLimitData(
            lastDrawingDate: nil,
            drawingsUsedToday: 0,
            lastResetDate: now,
            deviceIdentifier: keychain.getDeviceIdentifier()
        )

        saveDataToKeychain(resetData)
        timeUntilReset = resetWindow
        updateAvailability()

        print("DailyLimitManager: Counter reset")
    }

    private func updateAvailability() {
        loadDataFromKeychain()
        let usedCount = cachedData?.drawingsUsedToday ?? 0
        hasFreeDrawingAvailable = usedCount < freeDrawingsPerDay

        if !hasFreeDrawingAvailable {
            hasShownIndicatorThisSession = true
        }

        if hasFreeDrawingAvailable {
            startTimer()
        }
    }
}

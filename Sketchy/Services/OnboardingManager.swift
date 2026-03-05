//
//  OnboardingManager.swift
//  Sketchy
//
//  Created by Claude
//

import Foundation

/// Manages user onboarding status using UserDefaults
@MainActor
class OnboardingManager {

    // MARK: - Singleton

    static let shared = OnboardingManager()

    private init() {}

    // MARK: - UserDefaults Keys

    private let onboardingCompletedKey = "onboardingCompleted"

    // MARK: - Public Methods

    /// Check if user has completed onboarding
    func hasCompletedOnboarding() -> Bool {
        UserDefaults.standard.bool(forKey: onboardingCompletedKey)
    }

    /// Mark onboarding as completed
    func markOnboardingCompleted() {
        UserDefaults.standard.set(true, forKey: onboardingCompletedKey)
    }

    /// Reset onboarding status (for testing purposes)
    func resetOnboarding() {
        UserDefaults.standard.removeObject(forKey: onboardingCompletedKey)
    }
}

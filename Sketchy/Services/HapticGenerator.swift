//
//  HapticGenerator.swift
//  Sketchy
//
//  Created by Kazi Mashry on 6/3/26.
//

import CoreHaptics
import UIKit

class HapticGenerator {
    private var engine: CHHapticEngine?
    
    init() {
        prepareHaptics()
    }
    
    // Prepare haptic engine
    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Error creating haptic engine: \(error)")
        }
    }
    
    // Trigger impact haptic feedback
    static func triggerImpactHaptic(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    // Trigger notification haptic feedback
    static func triggerNotificationHaptic(type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
    
    // Trigger custom haptic pattern
    func triggerCustomHaptic(intensity: Float = 1.0, sharpness: Float = 0.8) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            let intensityParam = CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity)
            let sharpnessParam = CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensityParam, sharpnessParam],
                relativeTime: 0
            )
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Error playing custom haptic: \(error)")
        }
    }
}

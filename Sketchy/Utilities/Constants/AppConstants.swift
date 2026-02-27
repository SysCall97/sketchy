import Foundation
import UIKit
import AVFoundation

/// App-wide constants and magic numbers
enum AppConstants {
    // MARK: - Drawing

    static let defaultOpacity: Double = 0.5
    static let defaultBrightness: Double = 0.5
    static let minTemplateScale: CGFloat = 0.1
    static let maxTemplateScale: CGFloat = 5.0

    // MARK: - UI

    static let cornerRadius: CGFloat = 12
    static let controlPanelOpacity: Double = 0.7
    static let defaultPadding: CGFloat = 16

    // MARK: - Camera

    static let cameraSessionPreset = AVCaptureSession.Preset.high

    // MARK: - Templates

    static let thumbnailSize = CGSize(width: 120, height: 120)
    static let maxTemplateImportSize: CGFloat = 2048
}

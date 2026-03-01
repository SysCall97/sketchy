import Foundation
import UIKit
import Combine

/// ViewModel for the drawing screen - Manages all drawing state
@MainActor
class DrawingViewModel: ObservableObject, CameraServiceDelegate {
    @Published var state: DrawingState
    @Published var templateImage: UIImage?

    // Services
    var cameraService: CameraService  // Make accessible for CaptureControlsView
    private let flashlightService: FlashlightService
    private let brightnessService: BrightnessService
    private let autoLockService: AutoLockService

    // Metal rendering
    private var metalRenderer: MetalRenderer?

    init(
        template: TemplateModel,
        initialState: DrawingState? = nil,
        cameraService: CameraService? = nil
    ) {
        // Initialize services
        self.cameraService = cameraService ?? CameraService()
        self.flashlightService = FlashlightService()
        self.brightnessService = BrightnessService()
        self.autoLockService = AutoLockService()

        // Get current device brightness
        let deviceBrightness = Double(UIScreen.main.brightness)

        // Initialize state
        self.state = initialState ?? DrawingState(
            mode: DrawingState.DrawingMode.abovePaper,
            templateTransform: Transform.identity,
            cameraTransform: Transform.identity,
            opacity: 0.5,
            brightness: deviceBrightness,
            isFlashlightOn: false,
            transformTarget: DrawingState.TransformTarget.template,
            isTransformLocked: false,
            selectedTab: DrawingState.ControlTab.opacity,
            captureMode: DrawingState.CaptureMode.photo,
            isRecording: false,
            isFlashlightAvailable: true
        )

        // Load template
        self.templateImage = template.image

        // Set up camera delegate
        self.cameraService.delegate = self
    }

    // MARK: - Lifecycle

    func startDrawing() async {
        autoLockService.disableAutoLock()

        // Request camera permission if needed
        if state.mode == .abovePaper {
            let authorized = await cameraService.requestAuthorization()
            if authorized {
                cameraService.startSession()
            }
        } else {
            // Set initial brightness for under mode
            brightnessService.setBrightness(state.brightness)
        }
    }

    func stopDrawing() {
        cameraService.stopSession()
        flashlightService.toggle(false)
        brightnessService.restoreBrightness()
        autoLockService.enableAutoLock()
    }

    // MARK: - Mode Switching

    func switchMode(to mode: DrawingState.DrawingMode) async {
        let oldMode = state.mode

        // Preserve template transform
        let preservedTemplateTransform = state.templateTransform

        // Reset camera transform when leaving above mode
        let newCameraTransform: Transform
        if oldMode == .abovePaper && mode == .underPaper {
            newCameraTransform = .identity
        } else {
            newCameraTransform = state.cameraTransform
        }

        // Reset brightness to device brightness for under mode
        let newBrightness: Double
        if mode == .underPaper {
            newBrightness = Double(UIScreen.main.brightness)  // Use current device brightness
        } else {
            newBrightness = state.brightness
        }

        // Update state
        state = DrawingState(
            mode: mode,
            templateTransform: preservedTemplateTransform,  // PRESERVED
            cameraTransform: newCameraTransform,             // RESET if leaving above
            opacity: state.opacity,
            brightness: newBrightness,                       // RESET if entering under
            isFlashlightOn: false,                           // Always off on switch
            transformTarget: .template,                      // RESET
            isTransformLocked: false,                        // RESET
            selectedTab: mode == .underPaper ? .brightness : .opacity,  // Set default tab based on mode
            captureMode: .photo,                             // RESET to default
            isRecording: false,                              // RESET
            isFlashlightAvailable: true                      // RESET
        )

        await handleModeChange(mode: mode, from: oldMode)
    }

    private func handleModeChange(mode: DrawingState.DrawingMode, from oldMode: DrawingState.DrawingMode) async {
        switch mode {
        case .abovePaper:
            let authorized = await cameraService.requestAuthorization()
            if authorized {
                cameraService.startSession()
            }
            flashlightService.toggle(false)
            brightnessService.restoreBrightness()

        case .underPaper:
            cameraService.stopSession()
            flashlightService.toggle(false)
            brightnessService.setBrightness(state.brightness)
        }
    }

    // MARK: - Transform Management

    func updateTemplateTransform(_ transform: Transform) {
        guard !state.isTransformLocked else { return }
        guard state.transformTarget == .template else { return }
        state = state.with(templateTransform: transform)
    }

    func updateCameraTransform(_ transform: Transform) {
        guard !state.isTransformLocked else { return }
        guard state.transformTarget == .camera else { return }
        state = state.with(cameraTransform: transform)
    }

    func setTransformTarget(_ target: DrawingState.TransformTarget) {
        state = state.with(transformTarget: target)
    }

    func toggleTransformLock() {
        state = state.with(isTransformLocked: !state.isTransformLocked)
    }

    func resetCurrentTransform() {
        switch state.transformTarget {
        case .template:
            state = state.with(templateTransform: .identity)
        case .camera:
            state = state.with(cameraTransform: .identity)
        }
    }

    // MARK: - Opacity & Brightness

    func setOpacity(_ opacity: Double) {
        let clamped = max(0.0, min(1.0, opacity))
        state = state.with(opacity: clamped)
    }

    func setBrightness(_ brightness: Double) {
        guard state.mode == .underPaper else { return }
        let clamped = max(0.0, min(1.0, brightness))
        state = state.with(brightness: clamped)
        brightnessService.setBrightness(clamped)
    }

    // MARK: - Flashlight

    func toggleFlashlight() {
        guard state.mode == .abovePaper else { return }
        guard flashlightService.isAvailable else { return }

        let newState = !state.isFlashlightOn
        flashlightService.toggle(newState)
        state = state.with(isFlashlightOn: newState)
    }

    // MARK: - Tab Selection

    func setSelectedTab(_ tab: DrawingState.ControlTab) {
        state = state.with(selectedTab: tab)
    }

    // MARK: - Capture Mode

    func setCaptureMode(_ mode: DrawingState.CaptureMode) {
        // Can't change capture mode while recording
        guard !state.isRecording else { return }
        state = state.with(captureMode: mode)
    }

    // MARK: - Photo/Video Capture

    func capturePhoto(completion: @escaping (Result<URL, CaptureError>) -> Void) {
        cameraService.capturePhoto(completion: completion)
    }

    func startRecording(completion: @escaping (Result<Void, CaptureError>) -> Void) {
        guard state.mode == .abovePaper else {
            completion(.failure(.cameraNotAvailable))
            return
        }

        cameraService.startRecording { [weak self] result in
            switch result {
            case .success:
                self?.state = self?.state.with(isRecording: true) ?? self?.state ?? .initial
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func stopRecording(completion: @escaping (Result<URL, CaptureError>) -> Void) {
        cameraService.stopRecording { [weak self] result in
            self?.state = self?.state.with(isRecording: false) ?? self?.state ?? .initial
            completion(result)
        }
    }

    // MARK: - CameraServiceDelegate

    nonisolated func cameraService(_ service: CameraService, didReceiveFrame texture: CVPixelBuffer) {
        Task { @MainActor in
            // Update render state with new camera frame
            // This will be used by MetalRenderer
        }
    }
}

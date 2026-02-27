import AVFoundation
import Combine
import CoreVideo

/// Delegate for receiving camera frames
protocol CameraServiceDelegate: AnyObject {
    func cameraService(_ service: CameraService, didReceiveFrame texture: CVPixelBuffer)
}

/// Wrapper for AVFoundation camera capture
@MainActor
class CameraService: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var isRunning = false

    weak var delegate: CameraServiceDelegate?

    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.sketchy.camera.session")

    /// Expose session for preview layer
    var previewSession: AVCaptureSession {
        return session
    }

    override init() {
        super.init()
        setupSession()
    }

    // MARK: - Session Setup

    private func setupSession() {
        session.sessionPreset = .high

        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        ) else {
            print("CameraService: Failed to get camera device")
            return
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            }
        } catch {
            print("CameraService: Failed to create camera input: \(error)")
        }

        // Configure video output
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        // Set orientation
        if let connection = videoOutput.connection(with: .video) {
            connection.videoOrientation = .portrait
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .off
            }
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .authorized:
            isAuthorized = true
            return true
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            isAuthorized = granted
            return granted
        case .denied, .restricted:
            isAuthorized = false
            return false
        @unknown default:
            isAuthorized = false
            return false
        }
    }

    // MARK: - Session Control

    func startSession() {
        guard isAuthorized else { return }

        sessionQueue.async { [weak self] in
            self?.session.startRunning()
            Task { @MainActor in
                self?.isRunning = true
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
            Task { @MainActor in
                self?.isRunning = false
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                      didOutput sampleBuffer: CMSampleBuffer,
                      from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.delegate?.cameraService(self, didReceiveFrame: pixelBuffer)
        }
    }
}

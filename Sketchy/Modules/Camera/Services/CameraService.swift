import AVFoundation
import Combine
import CoreVideo
import Photos
import UIKit

/// Delegate for receiving camera frames
protocol CameraServiceDelegate: AnyObject {
    func cameraService(_ service: CameraService, didReceiveFrame texture: CVPixelBuffer)
}

/// Result type for capture operations
typealias CaptureResult<T> = Result<T, CaptureError>

enum CaptureError: LocalizedError {
    case cameraNotAvailable
    case notEnoughStorage(available: UInt64, required: UInt64)
    case permissionDenied
    case recordingFailed(Error)
    case saveFailed(Error)
    case photoCaptureFailed(Error)

    var errorDescription: String? {
        switch self {
        case .cameraNotAvailable:
            return "Camera is not available"
        case .notEnoughStorage(let available, let required):
            let availableMB = available / 1024 / 1024
            let requiredMB = required / 1024 / 1024
            return "Not enough storage. Available: \(availableMB)MB, Required: \(requiredMB)MB"
        case .permissionDenied:
            return "Camera permission is denied. Please enable it in Settings."
        case .recordingFailed(let error):
            return "Recording failed: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .photoCaptureFailed(let error):
            return "Photo capture failed: \(error.localizedDescription)"
        }
    }
}

/// Wrapper for AVFoundation camera capture
@MainActor
class CameraService: NSObject, ObservableObject {
    @Published var isAuthorized = false
    @Published var isRunning = false
    @Published var isRecording = false

    weak var delegate: CameraServiceDelegate?

    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let photoOutput = AVCapturePhotoOutput()
    private let movieOutput = AVCaptureMovieFileOutput()
    private let sessionQueue = DispatchQueue(label: "com.sketchy.camera.session")

    private var photoCaptureCompletion: ((CaptureResult<URL>) -> Void)?
    private var videoURL: URL?

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

        // Configure video data output (for preview)
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]

        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }

        // Set orientation for video output
        if let connection = videoOutput.connection(with: .video) {
            connection.videoOrientation = .portrait
            if connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .off
            }
        }

        // Add photo output
        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        }

        // Add movie output
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
        }

        // Set orientation for movie output
        if let connection = movieOutput.connection(with: .video) {
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

    // MARK: - Photo Capture

    func capturePhoto(completion: @escaping (CaptureResult<URL>) -> Void) {
        guard isAuthorized else {
            completion(.failure(.permissionDenied))
            return
        }

        guard isRunning else {
            completion(.failure(.cameraNotAvailable))
            return
        }

        // Check storage
        Task {
            let storageCheck = await checkAvailableStorage(required: 10 * 1024 * 1024) // 10MB buffer
            switch storageCheck {
            case .failure(let error):
                completion(.failure(error))
                return
            case .success:
                break
            }
        }

        photoCaptureCompletion = completion

        let settings = AVCapturePhotoSettings()

        // Check what quality modes are supported and use the best available
        if photoOutput.maxPhotoQualityPrioritization == .quality {
            settings.photoQualityPrioritization = .quality
        } else if photoOutput.maxPhotoQualityPrioritization == .balanced {
            settings.photoQualityPrioritization = .balanced
        } else {
            settings.photoQualityPrioritization = .speed
        }

        photoOutput.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - Video Recording

    func startRecording(completion: @escaping (CaptureResult<Void>) -> Void) {
        guard isAuthorized else {
            completion(.failure(.permissionDenied))
            return
        }

        guard isRunning else {
            completion(.failure(.cameraNotAvailable))
            return
        }

        guard !isRecording else {
            completion(.failure(.recordingFailed(NSError(domain: "CameraService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Already recording"]))))
            return
        }

        // Check storage (estimate 100MB per minute)
        Task {
            let storageCheck = await checkAvailableStorage(required: 100 * 1024 * 1024) // 100MB buffer
            switch storageCheck {
            case .failure(let error):
                completion(.failure(error))
                return
            case .success:
                break
            }
        }

        // Generate temporary file URL
        let tempDir = FileManager.default.temporaryDirectory
        let filename = UUID().uuidString + ".mov"
        videoURL = tempDir.appendingPathComponent(filename)

        sessionQueue.async { [weak self] in
            guard let self = self, let url = self.videoURL else {
                Task { @MainActor in
                    completion(.failure(.recordingFailed(NSError(domain: "CameraService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create video URL"]))))
                }
                return
            }

            self.movieOutput.startRecording(to: url, recordingDelegate: self)

            Task { @MainActor in
                self.isRecording = true
                completion(.success(()))
            }
        }
    }

    func stopRecording(completion: @escaping (CaptureResult<URL>) -> Void) {
        guard isRecording else {
            completion(.failure(.recordingFailed(NSError(domain: "CameraService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Not recording"]))))
            return
        }

        sessionQueue.async { [weak self] in
            self?.movieOutput.stopRecording()

            Task { @MainActor in
                self?.isRecording = false
            }
        }

        // Completion will be called in the delegate method
        self.videoRecordingCompletion = completion
    }

    private var videoRecordingCompletion: ((CaptureResult<URL>) -> Void)?

    // MARK: - Storage Check

    private func checkAvailableStorage(required: UInt64) async -> CaptureResult<Void> {
        let systemAttributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
        guard let availableSize = systemAttributes?[.systemSize] as? UInt64,
              let freeSize = systemAttributes?[.systemFreeSize] as? UInt64 else {
            return .failure(.notEnoughStorage(available: 0, required: required))
        }

        // Add 100MB buffer
        let buffer: UInt64 = 100 * 1024 * 1024
        let totalRequired = required + buffer

        if freeSize < totalRequired {
            return .failure(.notEnoughStorage(available: freeSize, required: totalRequired))
        }

        return .success(())
    }

    // MARK: - Save to Photo Library

    private func saveToPhotoLibrary(url: URL, completion: @escaping (CaptureResult<URL>) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                Task { @MainActor in
                    completion(.failure(.permissionDenied))
                }
                return
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        completion(.success(url))
                    } else {
                        completion(.failure(.saveFailed(error ?? NSError(domain: "CameraService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Unknown save error"]))))
                    }
                }
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

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraService: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            photoCaptureCompletion?(.failure(.photoCaptureFailed(error)))
            photoCaptureCompletion = nil
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            photoCaptureCompletion?(.failure(.photoCaptureFailed(NSError(domain: "CameraService", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to process image"]))))
            photoCaptureCompletion = nil
            return
        }

        // Save to temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let filename = UUID().uuidString + ".jpg"
        let url = tempDir.appendingPathComponent(filename)

        do {
            try imageData.write(to: url)

            // Save to photo library
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized else {
                    Task { @MainActor in
                        self.photoCaptureCompletion?(.failure(.permissionDenied))
                        self.photoCaptureCompletion = nil
                    }
                    return
                }

                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
                }) { success, error in
                    Task { @MainActor in
                        if success {
                            self.photoCaptureCompletion?(.success(url))
                        } else {
                            self.photoCaptureCompletion?(.failure(.saveFailed(error ?? NSError(domain: "CameraService", code: -6, userInfo: [NSLocalizedDescriptionKey: "Unknown save error"]))))
                        }
                        self.photoCaptureCompletion = nil
                    }
                }
            }
        } catch {
            photoCaptureCompletion?(.failure(.saveFailed(error)))
            photoCaptureCompletion = nil
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            videoRecordingCompletion?(.failure(.recordingFailed(error)))
        } else {
            // Save to photo library
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized else {
                    Task { @MainActor in
                        self.videoRecordingCompletion?(.failure(.permissionDenied))
                        self.videoRecordingCompletion = nil
                    }
                    return
                }

                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
                }) { success, error in
                    Task { @MainActor in
                        if success {
                            self.videoRecordingCompletion?(.success(outputFileURL))
                        } else {
                            self.videoRecordingCompletion?(.failure(.saveFailed(error ?? NSError(domain: "CameraService", code: -7, userInfo: [NSLocalizedDescriptionKey: "Unknown save error"]))))
                        }
                        self.videoRecordingCompletion = nil
                    }
                }
            }
        }
    }
}

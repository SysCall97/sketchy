import SwiftUI
import AVFoundation

/// UIView wrapper for camera preview layer
class CameraPreviewUIView: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }

    var previewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }

    func configure(with session: AVCaptureSession) {
        previewLayer.session = session
        previewLayer.videoGravity = .resizeAspectFill
    }
}

/// Camera preview view that wraps AVFoundation's camera output
struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> CameraPreviewUIView {
        let view = CameraPreviewUIView()
        view.configure(with: session)
        return view
    }

    func updateUIView(_ uiView: CameraPreviewUIView, context: Context) {
        uiView.configure(with: session)
    }
}

/// Wrapper view that manages camera session lifecycle
struct CameraView: View {
    @StateObject private var cameraService: CameraService

    init(cameraService: CameraService) {
        self._cameraService = StateObject(wrappedValue: cameraService)
    }

    var body: some View {
        CameraPreviewView(session: cameraService.previewSession)
    }
}

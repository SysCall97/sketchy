import AVFoundation

/// Service for controlling device flashlight/torch
class FlashlightService {
    private let queue = DispatchQueue(label: "com.sketchy.flashlight.queue")

    /// Check if flashlight is available on this device
    var isAvailable: Bool {
        guard let device = AVCaptureDevice.default(for: .video) else {
            return false
        }
        return device.hasTorch
    }

    /// Toggle flashlight on/off
    func toggle(_ isOn: Bool, completion: ((Bool) -> Void)? = nil) {
        queue.async { [weak self] in
            guard let device = AVCaptureDevice.default(for: .video),
                  device.hasTorch else {
                completion?(false)
                return
            }

            do {
                try device.lockForConfiguration()

                if isOn {
                    device.torchMode = .on
                    try device.setTorchModeOn(level: 1.0)
                } else {
                    device.torchMode = .off
                }

                device.unlockForConfiguration()
                completion?(true)
            } catch {
                print("FlashlightService error: \(error)")
                completion?(false)
            }
        }
    }

    /// Set flashlight intensity (0.0 - 1.0)
    func setIntensity(_ level: Float, completion: ((Bool) -> Void)? = nil) {
        queue.async {
            guard let device = AVCaptureDevice.default(for: .video),
                  device.hasTorch else {
                completion?(false)
                return
            }

            do {
                try device.lockForConfiguration()

                if level > 0 {
                    try device.setTorchModeOn(level: level)
                    device.torchMode = .on
                } else {
                    device.torchMode = .off
                }

                device.unlockForConfiguration()
                completion?(true)
            } catch {
                print("FlashlightService error: \(error)")
                completion?(false)
            }
        }
    }
}

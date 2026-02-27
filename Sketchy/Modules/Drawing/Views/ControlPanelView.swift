import SwiftUI

/// Control panel - Sliders and buttons for drawing controls
struct ControlPanelView: View {
    @ObservedObject var viewModel: DrawingViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Transform mode selector (Above mode only)
            if viewModel.state.mode == .abovePaper {
                TransformModePicker(
                    target: viewModel.state.transformTarget,
                    locked: viewModel.state.isTransformLocked,
                    onTargetChange: { target in
                        viewModel.setTransformTarget(target)
                    },
                    onLockToggle: {
                        viewModel.toggleTransformLock()
                    }
                )
            }

            // Opacity slider (both modes)
            OpacitySlider(
                value: viewModel.state.opacity,
                onChange: { value in
                    viewModel.setOpacity(value)
                }
            )

            // Brightness slider (Under mode only)
            if viewModel.state.mode == .underPaper {
                BrightnessSlider(
                    value: viewModel.state.brightness,
                    onChange: { value in
                        viewModel.setBrightness(value)
                    }
                )
            }

            // Flashlight toggle (Above mode only)
            if viewModel.state.mode == .abovePaper {
                FlashlightButton(
                    isOn: viewModel.state.isFlashlightOn,
                    isAvailable: true,  // TODO: Check from FlashlightService
                    onToggle: {
                        viewModel.toggleFlashlight()
                    }
                )
            }
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(16)
    }
}

// MARK: - Subcomponents

struct OpacitySlider: View {
    let value: Double
    let onChange: (Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Opacity: \(Int(value * 100))%")
                .font(.caption)
                .foregroundColor(.white)

            Slider(value: Binding(
                get: { value },
                set: { onChange($0) }
            ), in: 0...1)
            .tint(.blue)
        }
    }
}

struct BrightnessSlider: View {
    let value: Double
    let onChange: (Double) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Brightness: \(Int(value * 100))%")
                .font(.caption)
                .foregroundColor(.white)

            Slider(value: Binding(
                get: { value },
                set: { onChange($0) }
            ), in: 0.5...1)
            .tint(.yellow)
        }
    }
}

struct FlashlightButton: View {
    let isOn: Bool
    let isAvailable: Bool
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            Image(systemName: isOn ? "flashlight.on.fill" : "flashlight.off.fill")
                .font(.title)
                .foregroundColor(isOn ? .yellow : .white)
                .frame(width: 60, height: 60)
                .background(isOn ? Color.yellow.opacity(0.3) : Color.black.opacity(0.5))
                .cornerRadius(30)
        }
        .disabled(!isAvailable)
    }
}

struct TransformModePicker: View {
    let target: DrawingState.TransformTarget
    let locked: Bool
    let onTargetChange: (DrawingState.TransformTarget) -> Void
    let onLockToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Template button
            Button(action: { onTargetChange(.template) }) {
                Text("Template")
                    .font(.caption)
                    .fontWeight(target == .template ? .bold : .regular)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(target == .template ? Color.blue : Color.gray.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            // Camera button
            Button(action: { onTargetChange(.camera) }) {
                Text("Camera")
                    .font(.caption)
                    .fontWeight(target == .camera ? .bold : .regular)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(target == .camera ? Color.blue : Color.gray.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }

            Spacer()

            // Lock button
            Button(action: onLockToggle) {
                Image(systemName: locked ? "lock.fill" : "lock.open.fill")
                    .font(.title3)
                    .foregroundColor(locked ? .red : .white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(22)
            }
        }
    }
}

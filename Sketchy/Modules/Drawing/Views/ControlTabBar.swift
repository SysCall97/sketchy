import SwiftUI

/// Tab-based control panel for drawing interface
struct ControlTabBar: View {
    @ObservedObject var viewModel: DrawingViewModel
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            // Expandable content area (appears above tabs)
            if !isContentCollapsed {
                contentView
                    .padding(.bottom, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            // Tab bar
            HStack(spacing: 0) {
                // Opacity tab
                ControlTab(
                    icon: "circle.circle",
                    title: "Opacity",
                    isSelected: viewModel.state.selectedTab == .opacity
                ) {
                    viewModel.setSelectedTab(.opacity)
                }

                Divider()
                    .frame(height: 40)

                // Scaling tab
                ControlTab(
                    icon: "arrow.up.left.and.arrow.down.right",
                    title: "Scaling",
                    isSelected: viewModel.state.selectedTab == .scaling
                ) {
                    viewModel.setSelectedTab(.scaling)
                }

                Divider()
                    .frame(height: 40)

                // Camera tab
                ControlTab(
                    icon: "camera",
                    title: "Camera",
                    isSelected: viewModel.state.selectedTab == .camera
                ) {
                    viewModel.setSelectedTab(.camera)
                }

                Divider()
                    .frame(height: 40)

                // Flashlight tab
                ControlTab(
                    icon: viewModel.state.isFlashlightOn ? "flashlight.on.fill" : "flashlight.off.fill",
                    title: "Flashlight",
                    isSelected: viewModel.state.selectedTab == .flashlight
                ) {
                    // Always toggle flashlight when tapped
                    viewModel.toggleFlashlight()
                    // Update selected tab to flashlight
                    viewModel.setSelectedTab(.flashlight)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.8))
        }
        .alert("Error", isPresented: .constant(errorMessage != nil), presenting: errorMessage) { _ in
            Button("OK") {
                errorMessage = nil
            }
        } message: { error in
            Text(error)
        }
    }

    private var isContentCollapsed: Bool {
        // Flashlight tab is just a toggle, no expanded content
        viewModel.state.selectedTab == .flashlight
    }

    @ViewBuilder
    private var contentView: some View {
        Group {
            switch viewModel.state.selectedTab {
            case .opacity:
                opacityContent
            case .scaling:
                scalingContent
            case .camera:
                cameraContent
            case .flashlight:
                EmptyView()
            }
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(16)
    }

    // MARK: - Opacity Content

    private var opacityContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Opacity: \(Int(viewModel.state.opacity * 100))%")
                .font(.caption)
                .foregroundColor(.white)

            Slider(value: Binding(
                get: { viewModel.state.opacity },
                set: { viewModel.setOpacity($0) }
            ), in: 0...1)
            .tint(.blue)
        }
        .padding()
    }

    // MARK: - Scaling Content

    private var scalingContent: some View {
        VStack(spacing: 16) {
            // Picture/Camera picker
            Picker("Transform Target", selection: Binding(
                get: {
                    viewModel.state.transformTarget == .template ? 0 : 1
                },
                set: { newValue in
                    let target: DrawingState.TransformTarget = newValue == 0 ? .template : .camera
                    viewModel.setTransformTarget(target)
                }
            )) {
                Text("Picture").tag(0)
                Text("Camera").tag(1)
            }
            .pickerStyle(.segmented)

            // Reset button
            Button(action: {
                viewModel.resetCurrentTransform()
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Reset Position")
                }
                .font(.caption)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.8))
                .cornerRadius(8)
            }

            // Instructions
            Text(viewModel.state.transformTarget == .template ?
                 "Drag, pinch, and rotate to adjust the template" :
                 "Drag, pinch, and rotate to adjust the camera")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Camera Content

    private var cameraContent: some View {
        CaptureControlsView(viewModel: viewModel, errorMessage: $errorMessage)
    }
}

// MARK: - Control Tab Component

struct ControlTab: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .blue : .white)

                Text(title)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .blue : .white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
    }
}

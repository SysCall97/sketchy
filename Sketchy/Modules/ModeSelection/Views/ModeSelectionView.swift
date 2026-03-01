import SwiftUI
import AVFoundation

/// Mode selection screen - Choose between drawing modes
struct ModeSelectionView: View {
    @ObservedObject var coordinator: AppCoordinator
    let template: TemplateModel

    @StateObject private var viewModel: ModeSelectionViewModel
    @State private var showPermissionAlert = false
    @State private var permissionDeniedMessage = ""
    @State private var pendingMode: DrawingState.DrawingMode?

    init(coordinator: AppCoordinator, template: TemplateModel) {
        self.coordinator = coordinator
        self.template = template
        self._viewModel = StateObject(wrappedValue: ModeSelectionViewModel(template: template))
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                // Header
                VStack(spacing: 12) {
                    Text("Choose Drawing Mode")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("How would you like to draw?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 60)

                // Template preview
                if let image = template.image {
                    VStack(spacing: 8) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 150)
                            .cornerRadius(12)
                            .shadow(radius: 4)

                        Text(template.name.isEmpty ? "Selected Template" : template.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }

                // Mode options
                VStack(spacing: 20) {
                    ForEach(ModeSelectionState.DrawingMode.allCases, id: \.self) { mode in
                        ModeOptionCard(
                            mode: mode,
                            isSelected: viewModel.selectedMode == mode
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.selectedMode = mode
                            }
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Continue button
                Button(action: {
                    let selectedMode = viewModel.confirmSelection()
                    handleContinue(with: selectedMode)
                }) {
                    HStack {
                        Text("Continue")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(radius: 4)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarLeading) {
//                Button(action: {
//                    coordinator.goBack()
//                }) {
//                    HStack(spacing: 4) {
//                        Image(systemName: "chevron.left")
//                        Text("Back")
//                    }
//                    .foregroundColor(.blue)
//                }
//            }
//        }
        .alert("Camera Permission Required", isPresented: $showPermissionAlert) {
            Button("Cancel", role: .cancel) {
                pendingMode = nil
            }
            Button("Settings") {
                openAppSettings()
            }
        } message: {
            Text(permissionDeniedMessage)
        }
    }

    // MARK: - Camera Permission

    private func handleContinue(with mode: DrawingState.DrawingMode) {
        // Check if camera permission is needed for Above Paper mode
        if mode == .abovePaper {
            Task {
                await requestCameraPermissionAndProceed(mode: mode)
            }
        } else {
            // Under Paper mode doesn't need camera permission
            coordinator.goToDrawing(with: template, mode: mode)
        }
    }

    @MainActor
    private func requestCameraPermissionAndProceed(mode: DrawingState.DrawingMode) async {
        let status = AVCaptureDevice.authorizationStatus(for: .video)

        switch status {
        case .notDetermined:
            // Request permission
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            if granted {
                // Permission granted, proceed to drawing
                coordinator.goToDrawing(with: template, mode: mode)
            } else {
                // Permission denied
                showPermissionDeniedAlert()
            }

        case .authorized:
            // Permission already granted, proceed to drawing
            coordinator.goToDrawing(with: template, mode: mode)

        case .denied, .restricted:
            // Permission previously denied, show alert
            showPermissionDeniedAlert()

        @unknown default:
            break
        }
    }

    private func showPermissionDeniedAlert() {
        permissionDeniedMessage = "Camera access is needed for the Above Paper drawing mode. Please enable it in Settings to continue."
        showPermissionAlert = true
    }

    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Mode Option Card

struct ModeOptionCard: View {
    let mode: ModeSelectionState.DrawingMode
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: mode.icon)
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 60, height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.blue : Color.blue.opacity(0.1))
                    )

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.displayName)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)

                    Text(mode.description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.blue : Color.white)
                    .shadow(color: isSelected ? Color.blue.opacity(0.3) : Color.black.opacity(0.1), radius: isSelected ? 8 : 4)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

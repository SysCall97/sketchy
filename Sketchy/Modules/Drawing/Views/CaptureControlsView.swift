import SwiftUI

/// Camera capture controls with Photo/Video mode selection and Record button
struct CaptureControlsView: View {
    @ObservedObject var viewModel: DrawingViewModel
    @Binding var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            // Photo/Video picker
            Picker("Capture Mode", selection: Binding(
                get: { viewModel.state.captureMode },
                set: { newMode in
                    // Switch capture mode
                    viewModel.setCaptureMode(newMode)
                }
            )) {
                Text("Photo").tag(DrawingState.CaptureMode.photo)
                Text("Video").tag(DrawingState.CaptureMode.video)
            }
            .pickerStyle(.segmented)
            .background(Color.gray.opacity(0.3))
            .cornerRadius(8)

            // Record/Capture button
            Button(action: {
                switch viewModel.state.captureMode {
                case .photo:
                    viewModel.capturePhoto { result in
                        switch result {
                        case .success:
                            break // Photo saved successfully
                        case .failure(let error):
                            errorMessage = error.localizedDescription
                        }
                    }
                case .video:
                    if viewModel.state.isRecording {
                        viewModel.stopRecording { result in
                            switch result {
                            case .success:
                                break // Video saved successfully
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                            }
                        }
                    } else {
                        viewModel.startRecording { result in
                            switch result {
                            case .success:
                                break
                            case .failure(let error):
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                }
            }) {
                ZStack {
                    Circle()
                        .fill(viewModel.state.isRecording ? Color.red : Color.white)
                        .frame(width: 70, height: 70)

                    if viewModel.state.isRecording {
                        // Stop icon (square)
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 25, height: 25)
                            .cornerRadius(4)
                    } else {
                        // Recording indicator (inner circle)
                        Circle()
                            .stroke(Color.red, lineWidth: 3)
                            .frame(width: 60, height: 60)
                    }
                }
                .shadow(radius: 5)
            }
            .disabled(viewModel.state.isRecording && viewModel.state.captureMode == .photo)

            // Recording indicator
            if viewModel.state.isRecording {
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 10, height: 10)
                    Text("Recording...")
                        .font(.caption)
                        .foregroundColor(.white)
                }
                .transition(.opacity)
            }
        }
        .padding()
        .background(Color.black.opacity(0.7))
        .cornerRadius(16)
    }
}

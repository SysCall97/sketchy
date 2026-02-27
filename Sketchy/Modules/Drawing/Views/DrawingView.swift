import SwiftUI
import MetalKit

/// Main drawing interface - Container for drawing modes
struct DrawingView: View {
    @ObservedObject var coordinator: AppCoordinator
    let template: TemplateModel

    @StateObject private var viewModel: DrawingViewModel
    @StateObject private var cameraService: CameraService
    @State private var gestureHandler = TransformGestureHandler()

    init(coordinator: AppCoordinator, template: TemplateModel) {
        self.coordinator = coordinator
        self.template = template
        self._viewModel = StateObject(wrappedValue: DrawingViewModel(template: template))
        self._cameraService = StateObject(wrappedValue: CameraService())
    }

    var body: some View {
        ZStack {
            // Layer 1: Camera or white background
            if viewModel.state.mode == .abovePaper {
                CameraView(cameraService: cameraService)
                    .ignoresSafeArea()
            } else {
                Color.white
                    .ignoresSafeArea()
            }

            // Layer 2: Template image with bounding box overlay
            if let image = viewModel.templateImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .opacity(viewModel.state.opacity)
                    .overlay(
                        // Bounding box overlay (if unlocked and active)
                        Group {
                            if !viewModel.state.isTransformLocked &&
                               viewModel.state.transformTarget == .template {
                                Rectangle()
                                    .stroke(Color.white.opacity(0.8), lineWidth: 2)
                            }
                        }
                    )
                    .scaleEffect(viewModel.state.templateTransform.scale)
                    .offset(
                        x: viewModel.state.templateTransform.translation.x,
                        y: viewModel.state.templateTransform.translation.y
                    )
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if !viewModel.state.isTransformLocked &&
                                   viewModel.state.transformTarget == .template {
                                    let newTransform = gestureHandler.handleDrag(value, current: viewModel.state.templateTransform)
                                    viewModel.updateTemplateTransform(newTransform)
                                }
                            }
                            .onEnded { _ in
                                gestureHandler.handleDragEnded()
                            }
                    )
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                if !viewModel.state.isTransformLocked &&
                                   viewModel.state.transformTarget == .template {
                                    let newTransform = gestureHandler.handlePinch(value, current: viewModel.state.templateTransform)
                                    viewModel.updateTemplateTransform(newTransform)
                                }
                            }
                            .onEnded { _ in
                                gestureHandler.handlePinchEnded()
                            }
                    )
            }

            // Layer 4: UI Controls
            VStack {
                // Top: Mode switch + back button
                HStack {
                    Button(action: {
                        coordinator.goBack()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }

                    Spacer()

                    ModeSwitchView(
                        currentMode: viewModel.state.mode,
                        onModeChange: { mode in
                            Task {
                                await viewModel.switchMode(to: mode)
                            }
                        }
                    )
                }
                .padding()

                Spacer()

                // Bottom: Control panel
                ControlPanelView(viewModel: viewModel)
                .padding()
            }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .task {
            // Request camera authorization first
            let authorized = await cameraService.requestAuthorization()

            await viewModel.startDrawing()

            // Start camera if in above paper mode and authorized
            if viewModel.state.mode == .abovePaper && authorized {
                await cameraService.startSession()
            }
        }
        .onDisappear {
            viewModel.stopDrawing()
            cameraService.stopSession()
        }
        .onChange(of: viewModel.state.mode) { newMode in
            Task {
                if newMode == .abovePaper && cameraService.isAuthorized {
                    await cameraService.startSession()
                } else {
                    cameraService.stopSession()
                }
            }
        }
    }
}

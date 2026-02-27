import SwiftUI
import MetalKit

/// Main drawing interface - Container for drawing modes
struct DrawingView: View {
    @ObservedObject var coordinator: AppCoordinator
    let template: TemplateModel

    @StateObject private var viewModel: DrawingViewModel
    @StateObject private var cameraService: CameraService
    @State private var gestureHandler = TransformGestureHandler()
    @State private var isUIVisible = true

    init(coordinator: AppCoordinator, template: TemplateModel) {
        self.coordinator = coordinator
        self.template = template
        self._viewModel = StateObject(wrappedValue: DrawingViewModel(template: template))
        self._cameraService = StateObject(wrappedValue: CameraService())
    }

    var body: some View {
        ZStack {
            // Layer 1: Camera or white background (with transforms)
            GeometryReader { geometry in
                if viewModel.state.mode == .abovePaper {
                    CameraView(cameraService: cameraService)
                        .scaleEffect(viewModel.state.cameraTransform.scale)
                        .offset(
                            x: viewModel.state.cameraTransform.translation.x,
                            y: viewModel.state.cameraTransform.translation.y
                        )
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                } else {
                    Color.white
                        .ignoresSafeArea()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if !viewModel.state.isTransformLocked &&
                           viewModel.state.transformTarget == .camera &&
                           viewModel.state.mode == .abovePaper {
                            let newTransform = gestureHandler.handleDrag(value, current: viewModel.state.cameraTransform)
                            viewModel.updateCameraTransform(newTransform)
                        }
                    }
                    .onEnded { _ in
                        gestureHandler.handleDragEnded()
                    }
            )
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { value in
                        if !viewModel.state.isTransformLocked &&
                           viewModel.state.transformTarget == .camera &&
                           viewModel.state.mode == .abovePaper {
                            let newTransform = gestureHandler.handlePinch(value, current: viewModel.state.cameraTransform)
                            viewModel.updateCameraTransform(newTransform)
                        }
                    }
                    .onEnded { _ in
                        gestureHandler.handlePinchEnded()
                    }
            )

            // Layer 2: Template image with bounding box overlay
            if let image = viewModel.templateImage {
                GeometryReader { geometry in
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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .scaleEffect(viewModel.state.templateTransform.scale)
                        .offset(
                            x: viewModel.state.templateTransform.translation.x,
                            y: viewModel.state.templateTransform.translation.y
                        )
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                .simultaneousGesture(
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
                .offset(y: isUIVisible ? 0 : -150)
                .animation(.easeInOut(duration: 0.3), value: isUIVisible)

                Spacer()

                // Bottom: Control panel
                ControlPanelView(viewModel: viewModel)
                .padding()
                .offset(y: isUIVisible ? 0 : 500)
                .animation(.easeInOut(duration: 0.3), value: isUIVisible)
            }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .onTapGesture {
            // Toggle UI visibility on tap
            isUIVisible.toggle()
        }
        .task {
            // Record the drawing session (uses daily free drawing)
            DailyLimitManager.shared.recordDrawingSession()

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

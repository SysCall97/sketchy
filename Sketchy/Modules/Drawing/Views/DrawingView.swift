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

    init(coordinator: AppCoordinator, template: TemplateModel, initialMode: DrawingState.DrawingMode = .abovePaper) {
        self.coordinator = coordinator
        self.template = template

        // Create shared camera service
        let sharedCameraService = CameraService()

        // Get current device brightness
        let deviceBrightness = Double(UIScreen.main.brightness)

        // Create view model with shared camera service
        let initialState = DrawingState(
            mode: initialMode,
            templateTransform: .identity,
            cameraTransform: .identity,
            opacity: 0.5,
            brightness: deviceBrightness,
            isFlashlightOn: false,
            transformTarget: .template,
            isTransformLocked: false,
            selectedTab: .opacity,
            captureMode: .photo,
            isRecording: false,
            isFlashlightAvailable: true
        )

        self._cameraService = StateObject(wrappedValue: sharedCameraService)
        self._viewModel = StateObject(wrappedValue: DrawingViewModel(
            template: template,
            initialState: initialState,
            cameraService: sharedCameraService
        ))
    }

    var body: some View {
        ZStack {
            // Layer 1: Camera or white background (with transforms)
            GeometryReader { geometry in
                if viewModel.state.mode == .abovePaper {
                    ZStack {
                        CameraView(cameraService: cameraService)
                            .scaleEffect(viewModel.state.cameraTransform.scale)
                            .rotationEffect(Angle(radians: viewModel.state.cameraTransform.rotation))
                            .offset(
                                x: viewModel.state.cameraTransform.translation.x,
                                y: viewModel.state.cameraTransform.translation.y
                            )
                            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)

                        // Lock button for camera transform
                        if viewModel.state.transformTarget == .camera {
                            VStack {
                                HStack {
                                    Spacer()

                                    Button(action: {
                                        viewModel.toggleTransformLock()
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.black.opacity(0.6))
                                                .frame(width: 44, height: 44)

                                            Image(systemName: viewModel.state.isTransformLocked ? "lock.fill" : "lock.open.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(viewModel.state.isTransformLocked ? .orange : .white)
                                        }
                                    }
                                    .padding(8)
                                }
                                Spacer()
                            }
                        }
                    }
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
            .simultaneousGesture(
                RotationGesture()
                    .onChanged { value in
                        if !viewModel.state.isTransformLocked &&
                           viewModel.state.transformTarget == .camera &&
                           viewModel.state.mode == .abovePaper {
                            let newTransform = gestureHandler.handleRotation(value.radians, current: viewModel.state.cameraTransform)
                            viewModel.updateCameraTransform(newTransform)
                        }
                    }
                    .onEnded { _ in
                        gestureHandler.handleRotationEnded()
                    }
            )
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded {
                        if !viewModel.state.isTransformLocked &&
                            viewModel.state.transformTarget == .camera &&
                           viewModel.state.mode == .abovePaper {
                            viewModel.resetCurrentTransform()
                        }
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
                            // Bounding box overlay and lock button
                            ZStack {
                                if viewModel.state.transformTarget == .template {
                                    // Bounding box (if unlocked)
                                    if !viewModel.state.isTransformLocked {
                                        Rectangle()
                                            .stroke(Color.white.opacity(0.8), lineWidth: 2)
                                    }

                                    // Lock button (top-right corner)
                                    VStack {
                                        HStack {
                                            Spacer()

                                            Button(action: {
                                                viewModel.toggleTransformLock()
                                            }) {
                                                ZStack {
                                                    Circle()
                                                        .fill(Color.black.opacity(0.6))
                                                        .frame(width: 44, height: 44)

                                                    Image(systemName: viewModel.state.isTransformLocked ? "lock.fill" : "lock.open.fill")
                                                        .font(.system(size: 18))
                                                        .foregroundColor(viewModel.state.isTransformLocked ? .orange : .white)
                                                }
                                            }
                                            .padding(8)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .scaleEffect(viewModel.state.templateTransform.scale)
                        .rotationEffect(Angle(radians: viewModel.state.templateTransform.rotation))
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
                .simultaneousGesture(
                    RotationGesture()
                        .onChanged { value in
                            if !viewModel.state.isTransformLocked &&
                               viewModel.state.transformTarget == .template {
                                let newTransform = gestureHandler.handleRotation(value.radians, current: viewModel.state.templateTransform)
                                viewModel.updateTemplateTransform(newTransform)
                            }
                        }
                        .onEnded { _ in
                            gestureHandler.handleRotationEnded()
                        }
                )
                .simultaneousGesture(
                    TapGesture(count: 2)
                        .onEnded {
                            if !viewModel.state.isTransformLocked &&
                                viewModel.state.transformTarget == .template {
                                viewModel.resetCurrentTransform()
                            }
                        }
                )
            }

            // Layer 4: UI Controls
            VStack {
                // Top: Back button
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
                }
                .padding()
                .offset(y: isUIVisible ? 50 : -150)
                .animation(.easeInOut(duration: 0.3), value: isUIVisible)

                Spacer()

                // Bottom: Control tab bar
                ControlTabBar(viewModel: viewModel)
                .offset(y: isUIVisible ? 0 : 500)
                .animation(.easeInOut(duration: 0.3), value: isUIVisible)
            }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .ignoresSafeArea()
        .onTapGesture {
            // Toggle UI visibility on tap
            isUIVisible.toggle()
        }
        .task {
            // Record the drawing session (uses daily free drawing)
            DailyLimitManager.shared.recordDrawingSession()

            await viewModel.startDrawing()
        }
        .onDisappear {
            viewModel.stopDrawing()
            cameraService.stopSession()
        }
        .onChange(of: viewModel.state.mode) { newMode in
            Task {
                if newMode == .abovePaper {
                    await cameraService.startSession()
                } else {
                    cameraService.stopSession()
                }
            }
        }
    }
}

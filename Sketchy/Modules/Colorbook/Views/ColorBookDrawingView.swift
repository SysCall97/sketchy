import SwiftUI

/// Colorbook drawing interface - Main coloring view
struct ColorBookDrawingView: View {
    @ObservedObject var coordinator: AppCoordinator
    let coloringPage: TemplateModel

    @StateObject private var viewModel: ColorbookViewModel
//    @State private var gestureHandler = TransformGestureHandler()
    @State private var coloringImage: UIImage?
//    @State private var isUIVisible = true

    init(coordinator: AppCoordinator, coloringPage: TemplateModel) {
        self.coordinator = coordinator
        self.coloringPage = coloringPage
        self._viewModel = StateObject(wrappedValue: ColorbookViewModel())
    }

    var body: some View {
        ZStack {
            // Background
            Color(.systemGray6)
                .ignoresSafeArea()

            // Coloring page with transforms
            GeometryReader { geometry in
                if let image = coloringImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        .scaleEffect(viewModel.state.pageTransform.scale)
                        .rotationEffect(Angle(radians: viewModel.state.pageTransform.rotation))
                        .offset(
                            x: viewModel.state.pageTransform.translation.x,
                            y: viewModel.state.pageTransform.translation.y
                        )
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    // Handle tap for filling (basic implementation)
                                    // Note: This is a placeholder - actual flood fill requires image processing
                                    handleTap(at: value.location)
                                }
                        )
                } else {
                    ProgressView()
                }
            }
            .padding(.horizontal, 30)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // UI Controls
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
                .offset(y: 50)
//                .animation(.easeInOut(duration: 0.3), value: isUIVisible)

                Spacer()

                // Bottom: Control panel
                controlPanel
                    .offset(y: 0)
//                    .animation(.easeInOut(duration: 0.3), value: isUIVisible)
            }
        }
        .navigationBarHidden(true)
        .statusBar(hidden: true)
        .ignoresSafeArea()
//        .onTapGesture {
//            // Toggle UI visibility on tap
//            isUIVisible.toggle()
//        }
        .onAppear {
            loadImage()
        }
    }

    // MARK: - Control Panel

    private var controlPanel: some View {
        VStack(spacing: 16) {
            // Color picker and controls
            HStack(spacing: 20) {
                // Undo button
                Button(action: {
                    viewModel.undo()
                }) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.title2)
                        .foregroundColor(viewModel.canUndo() ? .primary : .gray)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                }
                .disabled(!viewModel.canUndo())

                // Color picker
                ColorPicker("", selection: Binding(
                    get: { viewModel.state.selectedColor },
                    set: { newColor in
                        viewModel.setColor(newColor)
                    }
                ))
                .frame(width: 60, height: 44)
                .padding(.horizontal)

                // Redo button
                Button(action: {
                    viewModel.redo()
                }) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.title2)
                        .foregroundColor(viewModel.canRedo() ? .primary : .gray)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                        .shadow(radius: 2)
                }
                .disabled(!viewModel.canRedo())
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 4)
            .padding(.horizontal)
        }
        .padding(.bottom, 20)
    }

    // MARK: - Actions

    private func loadImage() {
        // Load image from template
        if let localImage = coloringPage.image {
            coloringImage = localImage
        } else if let remoteURL = coloringPage.remoteURL {
            // Load from cache or URL
            if let cachedImage = ImageCache.shared.getImage(for: remoteURL) {
                coloringImage = cachedImage
            } else {
                Task {
                    do {
                        let image = try await ImageCache.shared.loadImage(from: remoteURL)
                        await MainActor.run {
                            coloringImage = image
                        }
                    } catch {
                        print("Failed to load image: \(error)")
                    }
                }
            }
        }
    }

    private func handleTap(at location: CGPoint) {
        // Note: This is a basic placeholder for tap-to-fill
        // A full implementation would:
        // 1. Convert tap point to image coordinates
        // 2. Implement flood fill algorithm
        // 3. Apply the fill to the image
        // 4. Update the display

        // For now, just record the operation
        viewModel.fill(at: location)

        // TODO: Implement actual flood fill
        print("Fill at: \(location) with color: \(viewModel.state.selectedColor)")
    }
}

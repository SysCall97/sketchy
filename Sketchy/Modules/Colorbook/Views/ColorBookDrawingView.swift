import SwiftUI
import CoreGraphics
import UIKit

/// Colorbook drawing interface - Main coloring view
struct ColorBookDrawingView: View {
    @ObservedObject var coordinator: AppCoordinator
    let coloringPage: TemplateModel

    @StateObject private var viewModel: ColorbookViewModel
    @State private var coloringImage: UIImage?
    @State private var imageSize: CGSize = .zero
    @State private var imagePosition: CGRect = .zero

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
                        .background(
                            GeometryReader { imageGeometry in
                                Color.clear
                                    .onAppear {
                                        // Calculate image frame for tap conversion
                                        let aspectRatio = image.size.width / image.size.height
                                        let viewWidth = geometry.size.width - 60 // Account for padding
                                        let viewHeight = geometry.size.height

                                        let renderWidth: CGFloat
                                        let renderHeight: CGFloat

                                        if viewWidth / aspectRatio <= viewHeight {
                                            renderWidth = viewWidth
                                            renderHeight = viewWidth / aspectRatio
                                        } else {
                                            renderHeight = viewHeight
                                            renderWidth = viewHeight * aspectRatio
                                        }

                                        imageSize = CGSize(width: image.size.width, height: image.size.height)
                                        imagePosition = CGRect(
                                            x: (geometry.size.width - renderWidth) / 2,
                                            y: (geometry.size.height - renderHeight) / 2,
                                            width: renderWidth,
                                            height: renderHeight
                                        )
                                    }
                            }
                        )
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    handleTap(at: value.location, in: geometry.size)
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

    private func handleTap(at location: CGPoint, in viewSize: CGSize) {
        guard let image = coloringImage else { return }

        // Convert tap location to image coordinates
        let transform = viewModel.state.pageTransform

        // Account for translation
        var adjustedLocation = CGPoint(
            x: location.x - transform.translation.x - 30, // 30 is horizontal padding
            y: location.y - transform.translation.y
        )

        // Account for scale (scale is centered)
        let centerX = viewSize.width / 2
        let centerY = viewSize.height / 2
        adjustedLocation = CGPoint(
            x: (adjustedLocation.x - centerX) / transform.scale + centerX,
            y: (adjustedLocation.y - centerY) / transform.scale + centerY
        )

        // Convert to image position
        guard imagePosition.contains(adjustedLocation) else { return }

        let relativeX = adjustedLocation.x - imagePosition.minX
        let relativeY = adjustedLocation.y - imagePosition.minY

        let imageX = Int((relativeX / imagePosition.width) * imageSize.width)
        let imageY = Int((relativeY / imagePosition.height) * imageSize.height)

        guard imageX >= 0, imageY >= 0,
              imageX < Int(imageSize.width), imageY < Int(imageSize.height) else { return }

        // Perform flood fill
        if let filledImage = floodFill(image: image, at: CGPoint(x: imageX, y: imageY), with: viewModel.state.selectedColor) {
            coloringImage = filledImage
            viewModel.fill(at: location)
        }
    }

    // MARK: - Flood Fill

    private func floodFill(image: UIImage, at point: CGPoint, with fillColor: Color) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height

        let x = Int(point.x)
        let y = Int(point.y)

        guard x >= 0, y >= 0, x < width, y < height else { return nil }

        // Create bitmap context
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard let context = CGContext(data: nil,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: 8,
                                    bytesPerRow: bytesPerRow,
                                    space: colorSpace,
                                    bitmapInfo: bitmapInfo) else { return nil }

        // Draw image to context
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Get pixel data
        guard let pixelData = context.data else { return nil }
        let data = pixelData.bindMemory(to: UInt8.self, capacity: width * height * bytesPerPixel)

        // Get target color (color to replace)
        let targetIndex = (y * width + x) * bytesPerPixel
        let targetR = data[targetIndex]
        let targetG = data[targetIndex + 1]
        let targetB = data[targetIndex + 2]
        let targetA = data[targetIndex + 3]

        // Convert SwiftUI Color to RGBA
        let fillColorRGBA = colorToRGBA(fillColor)

        // Check if tapping on same color
        if targetR == fillColorRGBA.r &&
           targetG == fillColorRGBA.g &&
           targetB == fillColorRGBA.b &&
           targetA == fillColorRGBA.a {
            return nil // Already filled with this color
        }

        // Tolerance for color matching (for anti-aliased lines)
        let tolerance: UInt8 = 30

        // BFS flood fill
        var queue = [(x, y)]
        var visited = Set<[Int]>()
        visited.insert([x, y])

        while !queue.isEmpty {
            let (cx, cy) = queue.removeFirst()

            // Check bounds
            if cx < 0 || cx >= width || cy < 0 || cy >= height { continue }

            let index = (cy * width + cx) * bytesPerPixel
            let r = data[index]
            let g = data[index + 1]
            let b = data[index + 2]
            let a = data[index + 3]

            // Check if pixel matches target color (within tolerance)
            if abs(Int(r) - Int(targetR)) <= Int(tolerance) &&
               abs(Int(g) - Int(targetG)) <= Int(tolerance) &&
               abs(Int(b) - Int(targetB)) <= Int(tolerance) &&
               abs(Int(a) - Int(targetA)) <= Int(tolerance) {

                // Fill pixel
                data[index] = fillColorRGBA.r
                data[index + 1] = fillColorRGBA.g
                data[index + 2] = fillColorRGBA.b
                data[index + 3] = fillColorRGBA.a

                // Add neighbors
                let neighbors = [(cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)]
                for (nx, ny) in neighbors {
                    if !visited.contains([nx, ny]) {
                        visited.insert([nx, ny])
                        queue.append((nx, ny))
                    }
                }
            }
        }

        // Create new image from context
        guard let newCGImage = context.makeImage() else { return nil }
        return UIImage(cgImage: newCGImage)
    }

    private func colorToRGBA(_ color: Color) -> (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        #if os(iOS)
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return (
            r: UInt8(red * 255),
            g: UInt8(green * 255),
            b: UInt8(blue * 255),
            a: UInt8(alpha * 255)
        )
        #else
        return (r: 255, g: 0, b: 0, a: 255)
        #endif
    }
}

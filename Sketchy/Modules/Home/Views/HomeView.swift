import SwiftUI
import Combine

/// Home screen - Template selection landing page
struct HomeView: View {
    @ObservedObject var coordinator: AppCoordinator
    @State private var templates = TemplateModel.bundledTemplates
    @State private var isPhotoPickerPresented = false
    @State private var selectedImage: UIImage?

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 8) {
                            Text("Sketchy")
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            Text("Select a template to start drawing")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)

                        // Template Gallery
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 20) {
                            ForEach(templates) { template in
                                TemplateThumbnail(template: template)
                                    .onTapGesture {
                                        coordinator.goToDrawing(with: template)
                                    }
                            }
                        }
                        .padding()

                        Spacer()
                            .frame(height: 80)
                    }
                }
                .navigationTitle("Sketchy")
                .navigationBarTitleDisplayMode(.inline)

                // Floating Import from Photos button
                VStack {
                    Spacer()

                    Button(action: {
                        isPhotoPickerPresented = true
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("Import from Photos")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $isPhotoPickerPresented) {
            PhotoPickerView(selectedImage: $selectedImage, isPresented: $isPhotoPickerPresented)
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                // Create a template from the selected image
                if let imageData = image.jpegData(compressionQuality: 0.9) {
                    let template = TemplateModel(name: "Photo", imageData: imageData)
                    coordinator.goToDrawing(with: template)
                }
                selectedImage = nil
            }
        }
    }
}

/// Template thumbnail component
struct TemplateThumbnail: View {
    let template: TemplateModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail image with original aspect ratio
            CachedAsyncImage(url: template.remoteURL, localImage: template.image)
        }
    }
}

/// Async image view with caching support
struct CachedAsyncImage: View {
    let url: String?
    let localImage: UIImage?

    @StateObject private var imageLoader = ImageLoader()
    @State private var loadedImage: UIImage?
    @State private var containerHeight: CGFloat = 150

    var body: some View {
        let displayImage: UIImage? = localImage ?? loadedImage

        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))

            if let image = displayImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if url != nil {
                // Loading state
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.2)
            } else {
                // Placeholder
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            }
        }
        .frame(height: containerHeight)
        .onAppear {
            // Calculate initial height for local image
            if let image = localImage {
                let aspectRatio = image.size.width / image.size.height
                containerHeight = 160 / aspectRatio
            }

            // Load remote image if needed
            if let urlString = url {
                imageLoader.loadImage(from: urlString) { image in
                    loadedImage = image
                    let aspectRatio = image.size.width / image.size.height
                    containerHeight = 160 / aspectRatio
                }
            }
        }
        .onChange(of: imageLoader.image) { newImage in
            if let image = newImage {
                let aspectRatio = image.size.width / image.size.height
                containerHeight = 160 / aspectRatio
            }
        }
    }
}

/// Image loader with caching
class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    private var cache = ImageCache.shared

    func loadImage(from urlString: String, completion: @escaping (UIImage) -> Void = { _ in }) {
        // Check cache first
        if let cachedImage = cache.getImage(for: urlString) {
            self.image = cachedImage
            completion(cachedImage)
            return
        }

        // Load from URL
        Task {
            do {
                let downloadedImage = try await cache.loadImage(from: urlString)
                await MainActor.run {
                    self.image = downloadedImage
                    completion(downloadedImage)
                }
            } catch {
                print("Failed to load image from \(urlString): \(error)")
            }
        }
    }
}

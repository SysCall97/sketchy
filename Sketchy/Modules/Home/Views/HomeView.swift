import SwiftUI
import Combine

/// Home screen - Template selection landing page
struct HomeView: View {
    @ObservedObject var coordinator: AppCoordinator
    @State private var templates = TemplateModel.bundledTemplates
    @State private var isPhotoPickerPresented = false
    @State private var selectedImage: UIImage?
    @State private var isPaywallPresented = false

    // Paywall flow state
    @State private var pendingTemplate: TemplateModel?
    @State private var pendingImage: UIImage?

    var body: some View {
        ZStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        // Header
                        VStack(spacing: 8) {

                            Text("Select a template to start drawing")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, shouldShowIndicator() ? 100 : 20)

                        // Template Gallery
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 20) {
                            ForEach(templates) { template in
                                TemplateThumbnail(template: template)
                                    .onTapGesture {
                                        handleTemplateSelection(template)
                                    }
                            }
                        }
                        .padding()

                        Spacer()
                            .frame(height: 100)
                    }
                }

                // Floating Daily Limit Indicator - positioned under nav bar
                VStack {
                    Spacer()
                        .frame(height: 10) // Account for navigation bar

                    DailyLimitIndicator(
                        limitManager: DailyLimitManager.shared,
                        subscriptionManager: coordinator.subscriptionManager,
                        onTapUpgrade: {
                            isPaywallPresented = true
                        }
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    .background(.clear)

                    Spacer()
                }

                // Floating Import from Photos button
                VStack {
                    Spacer()

                    Button(action: {
                        isPhotoPickerPresented = true
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("Import your illustration")
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
        .navigationTitle("Sketchy")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $isPhotoPickerPresented) {
            PhotoPickerView(selectedImage: $selectedImage, isPresented: $isPhotoPickerPresented)
        }
        .onChange(of: selectedImage) { newImage in
            if let image = newImage {
                // Store pending image and check if we can start drawing
                pendingImage = image

                if canStartDrawing() {
                    // Create a template from the selected image and proceed
                    if let imageData = image.jpegData(compressionQuality: 0.9) {
                        let template = TemplateModel(name: "Photo", imageData: imageData)
                        pendingImage = nil
                        coordinator.goToDrawing(with: template)
                    }
                } else {
                    // Show paywall
                    isPaywallPresented = true
                }
            }
        }
        .sheet(isPresented: $isPaywallPresented) {
            PaywallView(
                isPresented: $isPaywallPresented,
                subscriptionManager: coordinator.subscriptionManager,
                productID: "com.sketchy.subscription.weekly"
            )
        }
        .onChange(of: isPaywallPresented) { isPresented in
            // When paywall dismisses, check if user subscribed
            if !isPresented {
                handlePaywallDismissal()
            }
        }
    }

    // MARK: - Helper Methods

    private func shouldShowIndicator() -> Bool {
        let isSubscribed = coordinator.subscriptionManager.isSubscribedOrUnlockedAll()
        let shouldShowDailyLimit = DailyLimitManager.shared.shouldShowDailyLimitIndicator()
        return !isSubscribed && shouldShowDailyLimit
    }

    private func canStartDrawing() -> Bool {
        let isSubscribed = coordinator.subscriptionManager.isSubscribedOrUnlockedAll()
        return isSubscribed || DailyLimitManager.shared.canStartDrawing()
    }

    private func handleTemplateSelection(_ template: TemplateModel) {
        if canStartDrawing() {
            // User can draw, proceed directly
            coordinator.goToDrawing(with: template)
        } else {
            // Limit reached, show paywall
            pendingTemplate = template
            isPaywallPresented = true
        }
    }

    private func handlePaywallDismissal() {
        // Check if user subscribed after paywall
        if coordinator.subscriptionManager.isSubscribedOrUnlockedAll() {
            // Wait for paywall dismissal animation to complete, then proceed with pending drawing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                if let template = pendingTemplate {
                    pendingTemplate = nil
                    coordinator.goToDrawing(with: template)
                } else if let image = pendingImage {
                    if let imageData = image.jpegData(compressionQuality: 0.9) {
                        let template = TemplateModel(name: "Photo", imageData: imageData)
                        pendingImage = nil
                        coordinator.goToDrawing(with: template)
                    }
                }
            }
        } else {
            // User didn't subscribe, clear pending state
            pendingTemplate = nil
            pendingImage = nil
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
                .fill(Color.clear)

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
                    .foregroundColor(.clear)
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

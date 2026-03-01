import SwiftUI
import Combine
import Photos

/// Home screen - Template selection landing page
struct HomeView: View {
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject private var firebaseManager = FirebaseManager.shared
    @State private var templates = TemplateModel.localTemplates
    @State private var selectedTab: HomeTab = .home
    @State private var isPhotoPickerPresented = false
    @State private var selectedImage: UIImage?
    @State private var isPaywallPresented = false
    @State private var showPermissionAlert = false
    @State private var permissionDeniedMessage = ""

    // Paywall flow state
    @State private var pendingTemplate: TemplateModel?
    @State private var pendingImage: UIImage?

    // Favorites state - triggers view update when favorites change
    @State private var favoritesUpdateTrigger = UUID()

    // MARK: - Tabs

    enum HomeTab: String, CaseIterable {
        case home = "Home"
        case favorites = "Favorites"
        case projects = "Projects"
    }

    // MARK: - Computed Properties

    private var displayedTemplates: [TemplateModel] {
        if selectedTab == .home {
            return templates
        }

        let favoriteIDs = KeychainManager.shared.loadFavoriteTemplates()
        var result: [TemplateModel] = []

        for template in templates {
            let templateID = template.id.uuidString
            if favoriteIDs.contains(templateID) {
                result.append(template)
            }
        }

        return result
    }

    var body: some View {
        ZStack {
            scrollViewContent
            floatingDailyLimitIndicator
            floatingImportButton
            bottomTabBar
        }
        .background(Color(.systemGray6))
        .navigationTitle("Sketchy")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            firebaseManager.observeTemplates()
        }
        .onChange(of: firebaseManager.remoteTemplates) { remoteTemplates in
            templates = TemplateModel.localTemplates + remoteTemplates
        }
        .sheet(isPresented: $isPhotoPickerPresented) {
            PhotoPickerView(selectedImage: $selectedImage, isPresented: $isPhotoPickerPresented)
        }
        .onChange(of: selectedImage) { newImage in
            handleSelectedImage(newImage)
        }
        .sheet(isPresented: $isPaywallPresented) {
            PaywallView(
                isPresented: $isPaywallPresented,
                subscriptionManager: coordinator.subscriptionManager,
                productID: "com.sketchy.subscription.weekly"
            )
        }
        .onChange(of: isPaywallPresented) { isPresented in
            if !isPresented {
                handlePaywallDismissal()
            }
        }
        .alert("Permission Required", isPresented: $showPermissionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Settings") {
                openAppSettings()
            }
        } message: {
            Text(permissionDeniedMessage)
        }
    }

    // MARK: - View Components

    private var scrollViewContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                headerSection
                templateGrid
                Spacer()
                    .frame(height: 100)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Select a template to start drawing")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, shouldShowIndicator() ? 100 : 20)
    }

    private var templateGrid: some View {
        Group {
            if selectedTab == .projects {
                ProjectsListView(coordinator: coordinator)
            } else if displayedTemplates.isEmpty && selectedTab == .favorites {
                emptyFavoritesState
            } else {
                actualTemplateGrid
            }
        }
        .id(favoritesUpdateTrigger) // Refresh grid when favorites change
    }

    private var actualTemplateGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 20) {
            ForEach(displayedTemplates) { template in
                TemplateThumbnail(
                    template: template,
                    onFavoriteToggle: {
                        // Trigger view update when favorite status changes
                        favoritesUpdateTrigger = UUID()
                    }
                )
                .id(template.id.uuidString + selectedTab.rawValue)
                .onTapGesture {
                    handleTemplateSelection(template)
                }
            }
        }
        .padding()
    }

    private var emptyFavoritesState: some View {
        VStack(spacing: 20) {
            Spacer()
                .frame(height: 60)

            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "star")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                    .rotationEffect(.degrees(isRotating ? 15 : 0))
                    .animation(
                        Animation.easeInOut(duration: 1.5)
                            .repeatForever(autoreverses: true),
                        value: isRotating
                    )
            }

            VStack(spacing: 8) {
                Text("No Favorites Yet")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("Tap the star icon on any template to add it to your favorites")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
        .onAppear {
            isRotating = true
        }
    }

    @State private var isRotating = false

    private var floatingDailyLimitIndicator: some View {
        VStack {
            Spacer()
                .frame(height: 10)

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
    }

    private var floatingImportButton: some View {
        VStack {
            Spacer()

            Button(action: {
                Task {
                    await requestPhotoLibraryPermission()
                }
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
            .padding(.bottom, 60)
        }
    }

    private var bottomTabBar: some View {
        VStack {
            Spacer()

            HStack(spacing: 0) {
                ForEach(HomeTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedTab = tab
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: iconName(for: tab))
                                .font(.system(size: 20))
                            Text(tab.rawValue)
                                .font(.caption2)
                        }
                        .foregroundColor(selectedTab == tab ? .blue : .gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(Color.white)
            .cornerRadius(12, corners: [.topLeft, .topRight])
        }
        .ignoresSafeArea()
    }

    private func iconName(for tab: HomeTab) -> String {
        switch tab {
        case .home:
            return "house.fill"
        case .favorites:
            return "star.fill"
        case .projects:
            return "folder.fill"
        }
    }

    // MARK: - Helper Methods

    // MARK: - Helper Methods

    private func handleSelectedImage(_ newImage: UIImage?) {
        guard let image = newImage else { return }

        pendingImage = image

        if canStartDrawing() {
            if let imageData = image.jpegData(compressionQuality: 0.9) {
                let template = TemplateModel(name: "Photo", imageData: imageData)
                pendingImage = nil
                coordinator.goToDrawing(with: template)
            }
        } else {
            isPaywallPresented = true
        }
    }

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

    // MARK: - Permissions

    @MainActor
    private func requestPhotoLibraryPermission() async {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        switch status {
        case .notDetermined:
            // Request permission
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            if newStatus == .authorized || newStatus == .limited {
                // Permission granted, show photo picker
                isPhotoPickerPresented = true
            } else {
                // Permission denied
                showPermissionAlert(for: "Photo library access is needed to import your own drawing templates.")
            }

        case .authorized, .limited:
            // Permission already granted, show photo picker
            isPhotoPickerPresented = true

        case .denied, .restricted:
            // Permission denied, show alert with settings option
            showPermissionAlert(for: "Photo library access is needed to import your own drawing templates. Please enable it in Settings.")

        @unknown default:
            break
        }
    }

    private func showPermissionAlert(for message: String) {
        permissionDeniedMessage = message
        showPermissionAlert = true
    }

    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

/// Template thumbnail component
struct TemplateThumbnail: View {
    let template: TemplateModel
    var onFavoriteToggle: (() -> Void)? = nil
    @State private var isFavorite: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail image with favorite star overlay
            ZStack(alignment: .topTrailing) {
                CachedAsyncImage(url: template.remoteURL, localImage: template.image)

                // Favorite star button
                Button(action: {
                    toggleFavorite()
                }) {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .font(.title2)
                        .foregroundColor(isFavorite ? .yellow : Color(.systemGray3))
                        .padding(8)
                }
                .padding(8)
            }
        }
        .onAppear {
            // Load favorite status on appear
            isFavorite = KeychainManager.shared.isTemplateFavorite(template.id.uuidString)
        }
    }

    private func toggleFavorite() {
        isFavorite.toggle()
        let templateID = template.id.uuidString

        if isFavorite {
            KeychainManager.shared.addFavoriteTemplate(templateID)
        } else {
            KeychainManager.shared.removeFavoriteTemplate(templateID)
        }

        // Notify parent of favorite change
        onFavoriteToggle?()
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

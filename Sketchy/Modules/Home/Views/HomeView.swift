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
    @State private var isOfferPaywallPresented = false
    @State private var showPermissionAlert = false
    @State private var permissionDeniedMessage = ""

    // Paywall flow state
    @State private var pendingTemplate: TemplateModel?
    @State private var pendingImage: UIImage?

    // Favorites state - triggers view update when favorites change
    @State private var favoritesUpdateTrigger = UUID()

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
//            floatingImportButton
            bottomTabBar
            floatingPromoButton  // Moved to top so it's not covered
        }
        .background(Color(.systemGray6))
        .navigationTitle("Sketchy")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if !coordinator.subscriptionManager.isSubscribedOrUnlockedAll() {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isPaywallPresented = true
                    }) {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.body)
                    }
                }
            }
        }
        .onAppear {
            KeychainManager.shared.resetAll()
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
        .sheet(isPresented: $isOfferPaywallPresented) {
            OfferPaywallView(
                isPresented: $isOfferPaywallPresented,
                subscriptionManager: coordinator.subscriptionManager
            )
        }
        .onChange(of: isPaywallPresented) { isPresented in
            if !isPresented {
                handlePaywallDismissal()
            }
        }
        .onChange(of: isOfferPaywallPresented) { isPresented in
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
            Text("Select a \(selectedTab == .projects ? "project" : "template") to start drawing")
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

    private var floatingPromoButton: some View {
        VStack {
            if !coordinator.subscriptionManager.isSubscribedOrUnlockedAll() {
                Spacer()

                HStack {
                    Spacer()
                    PromoFloatingButton(isPaywallPresented: $isOfferPaywallPresented)
                        .padding(.trailing, 16)
                        .padding(.bottom, 100)
                }
            }
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
            
            ZStack(alignment: .top) {
                TabBarWithHole()
                    .fill(Color.white)
                    .frame(height: 80)
                    .cornerRadius(12, corners: [.topLeft, .topRight])
                    .shadow(color: .black.opacity(0.1), radius: 5, y: -2)
                
                HStack(spacing: 0) {
                    ForEach(HomeTab.allCases, id: \.self) { tab in
                        if tab == HomeTab.allCases[HomeTab.allCases.count/2] {
                            Spacer().frame(width: 80)
                        }
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                if tab == .colorbook {
                                    // Navigate to colorbook view
                                    coordinator.goToColorbook()
                                } else {
                                    selectedTab = tab
                                }
                            }
                        }) {
                            VStack(spacing: 4) {
                                Image(systemName: tab.iconName())
                                    .font(.system(size: 20))
                                Text(tab.rawValue)
                                    .font(.caption2)
                            }
                            .foregroundColor(selectedTab == tab ? .blue : .gray)
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.top, 12)
                
                Button(action: {
                    Task {
                        await requestPhotoLibraryPermission()
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.title.bold())
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(Circle().fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        ))
                        .shadow(radius: 4)
                }
                .offset(y: -30)
            }
        }
        .ignoresSafeArea()
    }

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
        if coordinator.subscriptionManager.isSubscribedOrUnlockedAll() {
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

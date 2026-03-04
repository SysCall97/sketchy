import SwiftUI

/// Colorbook gallery view - displays coloring page templates
struct ColorbookView: View {
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject private var firebaseManager = FirebaseManager.shared
    @State private var templates = TemplateModel.localTemplates
    @State private var isPaywallPresented = false

    // Filter colorbook templates (for now, show all templates)
    private var coloringPages: [TemplateModel] {
        return templates.filter { template in
            // Filter for colorbook templates based on name or metadata
            // For now, show all templates
            return true
        }
    }

    var body: some View {
        ZStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 30) {
                    headerSection
                    templateGrid
                    Spacer()
                        .frame(height: 100)
                }
            }
        }
        .background(Color(.systemGray6))
        .navigationTitle("Colorbook")
        .navigationBarTitleDisplayMode(.large)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    coordinator.goBack()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
                        .font(.title3)
                }
            }
        }
        .onAppear {
            firebaseManager.observeTemplates()
        }
        .onChange(of: firebaseManager.remoteTemplates) { remoteTemplates in
            templates = TemplateModel.localTemplates + remoteTemplates
        }
        .sheet(isPresented: $isPaywallPresented) {
            PaywallView(
                isPresented: $isPaywallPresented,
                subscriptionManager: coordinator.subscriptionManager,
                productID: "com.sketchy.subscription.weekly"
            )
        }
    }

    // MARK: - View Components

    private var headerSection: some View {
        VStack(spacing: 8) {
            Text("Select a coloring page to start")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }

    private var templateGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 20) {
            ForEach(coloringPages) { template in
                TemplateThumbnail(
                    template: template,
                    onFavoriteToggle: nil
                )
                .id(template.id.uuidString)
                .onTapGesture {
                    handleTemplateSelection(template)
                }
            }
        }
        .padding()
    }

    // MARK: - Actions

    private func handleTemplateSelection(_ template: TemplateModel) {
        // Check subscription/daily limit
        let isSubscribed = coordinator.subscriptionManager.isSubscribedOrUnlockedAll()
        let canStart = isSubscribed || DailyLimitManager.shared.canStartDrawing()

        if canStart {
            coordinator.goToColorbookDrawing(with: template)
        } else {
            isPaywallPresented = true
        }
    }
}

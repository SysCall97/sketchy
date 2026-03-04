import SwiftUI

/// Template thumbnail component with favorite toggle
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

import SwiftUI

/// Home screen - Template selection landing page
struct HomeView: View {
    @ObservedObject var coordinator: AppCoordinator
    @State private var templates = TemplateModel.bundledTemplates

    var body: some View {
        NavigationView {
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

                    // Import from Photos button
                    Button(action: {
                        coordinator.goToTemplateGallery()
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
                    }
                    .padding(.horizontal)

                    Spacer()
                }
            }
            .navigationTitle("Sketchy")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// Template thumbnail component
struct TemplateThumbnail: View {
    let template: TemplateModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Thumbnail image
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 150)

                if let image = template.thumbnail {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                }
            }

            // Template name
            Text(template.name)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(1)
        }
    }
}

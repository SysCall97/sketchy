import SwiftUI

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

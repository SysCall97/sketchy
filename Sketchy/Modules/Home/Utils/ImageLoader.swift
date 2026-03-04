import Combine
import SwiftUI

/// Image loader with caching support for remote images
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

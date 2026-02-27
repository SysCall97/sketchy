import Foundation
import UIKit

/// Thread-safe image cache for URL-based images
class ImageCache {
    static let shared = ImageCache()

    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        // Setup memory cache
        cache.countLimit = 100
        cache.totalCostLimit = 100 * 1024 * 1024 // 100 MB

        // Setup disk cache directory
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = caches.appendingPathComponent("ImageCache")

        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    /// Get image from cache (memory or disk)
    func getImage(for url: String) -> UIImage? {
        // Check memory cache first
        if let image = cache.object(forKey: url as NSString) {
            return image
        }

        // Check disk cache
        let fileURL = cacheDirectory.appendingPathComponent(cacheKey(for: url))
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }

        // Store in memory cache
        cache.setObject(image, forKey: url as NSString)
        return image
    }

    /// Save image to cache (memory and disk)
    func setImage(_ image: UIImage, for url: String) {
        // Store in memory cache
        cache.setObject(image, forKey: url as NSString)

        // Store in disk cache
        let fileURL = cacheDirectory.appendingPathComponent(cacheKey(for: url))
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: fileURL)
        }
    }

    /// Load image from URL asynchronously with caching
    func loadImage(from urlString: String) async throws -> UIImage {
        // Check cache first
        if let cachedImage = getImage(for: urlString) {
            return cachedImage
        }

        // Validate URL
        guard let url = URL(string: urlString) else {
            throw ImageCacheError.invalidURL
        }

        // Download image
        let (data, _) = try await URLSession.shared.data(from: url)

        guard let image = UIImage(data: data) else {
            throw ImageCacheError.invalidImageData
        }

        // Cache the image
        setImage(image, for: urlString)

        return image
    }

    // MARK: - Private Helpers

    private func cacheKey(for url: String) -> String {
        return url.data(using: .utf8)?.base64EncodedString() ?? url
    }
}

enum ImageCacheError: Error {
    case invalidURL
    case invalidImageData
}

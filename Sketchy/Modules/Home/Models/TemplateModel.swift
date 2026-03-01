import UIKit
import Foundation

/// Represents a drawing template that can be traced
struct TemplateModel: Identifiable, Equatable, Hashable, Codable {
    let id: UUID
    let name: String
    let source: TemplateSource

    enum TemplateSource: Equatable, Hashable, Codable {
        case bundled(String)      // Asset name in bundle
        case remote(String)       // URL string for remote image
        case imported(Data)       // Image data from user import
    }

    // MARK: - Firebase Decodable Support

    /// Custom decoding for Firebase JSON structure
    /// Firebase format: [{"id": "uuid-string", "name": "image-url"}]
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode id
        let idString = try container.decode(String.self, forKey: .id)
        guard let idUUID = UUID(uuidString: idString) else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Invalid UUID string")
        }
        self.id = idUUID

        // Decode name (which is actually the URL for Firebase templates)
        let urlString = try container.decode(String.self, forKey: .name)

        // Detect if it's a URL and set source accordingly
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            self.name = ""  // Firebase templates don't have names
            self.source = .remote(urlString)
        } else {
            self.name = urlString
            self.source = .bundled(urlString)
        }
    }

    /// Standard encoding support
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id.uuidString, forKey: .id)

        // For encoding, we use the source to determine what to store in "name"
        switch source {
        case .remote(let url):
            try container.encode(url, forKey: .name)
        case .bundled(let assetName):
            try container.encode(name.isEmpty ? assetName : name, forKey: .name)
        case .imported:
            // Can't encode imported data to Firebase format
            try container.encode(name, forKey: .name)
        }
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
    }

    /// Check if this template has a remote source
    var isRemote: Bool {
        if case .remote = source {
            return true
        }
        return false
    }

    /// Get the remote URL string if applicable
    var remoteURL: String? {
        if case .remote(let urlString) = source {
            return urlString
        }
        return nil
    }

    /// The template image (only for local assets)
    var image: UIImage? {
        switch source {
        case .bundled(let assetName):
            return UIImage(named: assetName)
        case .imported(let imageData):
            return UIImage(data: imageData)
        case .remote:
            return nil // Remote images loaded asynchronously
        }
    }

    /// Thumbnail version for gallery display (only for local assets)
    var thumbnail: UIImage? {
        guard let image = image else { return nil }
        let size = CGSize(width: 120, height: 120)

        // Scale the image to thumbnail size
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }

        image.draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }

    /// Initializer with bundled template
    init(id: UUID = UUID(), name: String, bundledAssetName: String) {
        self.id = id
        self.name = name
        // Detect if it's a URL
        if bundledAssetName.hasPrefix("http://") || bundledAssetName.hasPrefix("https://") {
            self.source = .remote(bundledAssetName)
        } else {
            self.source = .bundled(bundledAssetName)
        }
    }

    /// Initializer with imported image
    init(id: UUID = UUID(), name: String, imageData: Data) {
        self.id = id
        self.name = name
        self.source = .imported(imageData)
    }
}

// MARK: - Default Templates

extension TemplateModel {
    /// Built-in templates included with the app (local assets only)
    static let localTemplates: [TemplateModel] = [
        TemplateModel(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, name: "", bundledAssetName: "alpaca"),
        TemplateModel(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, name: "", bundledAssetName: "bird"),
        TemplateModel(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, name: "", bundledAssetName: "bunny"),
        TemplateModel(id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!, name: "", bundledAssetName: "cat"),
        TemplateModel(id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!, name: "", bundledAssetName: "sword"),
        TemplateModel(id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!, name: "", bundledAssetName: "fox"),
        TemplateModel(id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!, name: "", bundledAssetName: "witch"),
        TemplateModel(id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!, name: "", bundledAssetName: "bird2")
    ]

    /// All available templates (local + Firebase remote)
    /// Combines bundled local templates with remote templates from Firebase
    static var bundledTemplates: [TemplateModel] {
        localTemplates + FirebaseManager.shared.remoteTemplates
    }
}

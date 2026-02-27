import UIKit
import Foundation

/// Represents a drawing template that can be traced
struct TemplateModel: Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let source: TemplateSource

    enum TemplateSource: Equatable, Hashable {
        case bundled(String)      // Asset name in bundle
        case remote(String)       // URL string for remote image
        case imported(Data)       // Image data from user import
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
    /// Built-in templates included with the app
    static let bundledTemplates: [TemplateModel] = [
        TemplateModel(name: "", bundledAssetName: "alpaca"),
        TemplateModel(name: "", bundledAssetName: "bird"),
        TemplateModel(name: "", bundledAssetName: "bunny"),
        TemplateModel(name: "", bundledAssetName: "cat"),
        TemplateModel(name: "", bundledAssetName: "sword"),
        TemplateModel(name: "", bundledAssetName: "fox"),
        TemplateModel(name: "", bundledAssetName: "witch"),
        TemplateModel(name: "", bundledAssetName: "bird2")
    ]
}

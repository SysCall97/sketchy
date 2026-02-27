import UIKit

/// Represents a drawing template that can be traced
struct TemplateModel: Identifiable, Equatable {
    let id: UUID
    let name: String
    let source: TemplateSource

    enum TemplateSource: Equatable {
        case bundled(String)      // Asset name in bundle
        case imported(Data)       // Image data from user import
    }

    /// The template image
    var image: UIImage? {
        switch source {
        case .bundled(let assetName):
            return UIImage(named: assetName)
        case .imported(let imageData):
            return UIImage(data: imageData)
        }
    }

    /// Thumbnail version for gallery display
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
        self.source = .bundled(bundledAssetName)
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
        TemplateModel(name: "Alpaca", bundledAssetName: "alpaca"),
        TemplateModel(name: "Bird", bundledAssetName: "bird"),
        TemplateModel(name: "Bunny", bundledAssetName: "bunny"),
        TemplateModel(name: "Cat", bundledAssetName: "cat"),
        TemplateModel(name: "Sword", bundledAssetName: "sword"),
        TemplateModel(name: "Fox", bundledAssetName: "fox")
    ]
}

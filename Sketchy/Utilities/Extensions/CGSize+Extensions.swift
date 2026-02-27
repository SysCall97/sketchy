import Foundation
import CoreGraphics

// MARK: - CGSize Extensions

extension CGSize {
    /// Aspect ratio (width / height)
    var aspectRatio: CGFloat {
        guard height != 0 else { return 1.0 }
        return width / height
    }

    /// Scale size by a factor
    func scaled(by factor: CGFloat) -> CGSize {
        CGSize(width: width * factor, height: height * factor)
    }

    /// Fit size within a bounding size while maintaining aspect ratio
    func fitting(in boundingSize: CGSize) -> CGSize {
        let aspectRatio = self.aspectRatio
        let boundingAspectRatio = boundingSize.aspectRatio

        if aspectRatio > boundingAspectRatio {
            // Width is constrained
            let width = boundingSize.width
            let height = width / aspectRatio
            return CGSize(width: width, height: height)
        } else {
            // Height is constrained
            let height = boundingSize.height
            let width = height * aspectRatio
            return CGSize(width: width, height: height)
        }
    }
}

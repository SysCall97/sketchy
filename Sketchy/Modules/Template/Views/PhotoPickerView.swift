import SwiftUI
import PhotosUI
import UniformTypeIdentifiers

/// Photo picker for importing templates from the photo library
struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // Dismiss the picker if isPresented becomes false
        if !isPresented {
            uiViewController.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView

        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }

        func didCancel() {
            parent.isPresented = false
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.isPresented = false

            guard let result = results.first else { return }

            let itemProvider = result.itemProvider

            // Check if the item provider can load an image
            if itemProvider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                // Use loadFileRepresentation for iOS 15+ compatibility
                itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier, completionHandler: { [weak self] url, error in
                    defer {
                        // Clean up temporary file
                        if let url = url {
                            try? FileManager.default.removeItem(at: url)
                        }
                    }

                    if let error = error {
                        print("Error loading image: \(error)")
                        return
                    }

                    guard let url = url else { return }

                    // Load image from URL
                    if let data = try? Data(contentsOf: url),
                       let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self?.parent.selectedImage = image
                            print("Successfully loaded image from photo library")
                        }
                    }
                })
            }
        }
    }
}




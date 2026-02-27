import SwiftUI
import Photos

/// Template gallery - Browse and select templates
struct TemplateGalleryView: View {
    @ObservedObject var coordinator: AppCoordinator
    @State private var selectedImage: UIImage?
    @State private var showPhotoPicker = false
    @State private var importedTemplates: [TemplateModel] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Import button
                    Button(action: {
                        checkPermissionAndShowPicker()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
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

                    // Imported templates
                    if !importedTemplates.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Templates")
                                .font(.headline)
                                .padding(.horizontal)

                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 20) {
                                ForEach(importedTemplates) { template in
                                    TemplateThumbnail(template: template)
                                        .onTapGesture {
                                            coordinator.goToDrawing(with: template)
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)

                            Text("No imported templates yet")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            Text("Import images from your photo library\nto use as drawing templates")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 60)
                    }

                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showPhotoPicker) {
            PhotoPickerView(
                selectedImage: $selectedImage,
                isPresented: $showPhotoPicker
            )
        }
        .onChange(of: selectedImage) { newValue in
            guard let image = newValue else { return }

            // Convert image to JPEG data
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("Failed to convert image to JPEG")
                return
            }

            // Create template
            let template = TemplateModel(
                name: "Custom \(importedTemplates.count + 1)",
                imageData: imageData
            )
            importedTemplates.append(template)

            // Reset selected image to allow importing another image
            selectedImage = nil

            // Navigate to drawing screen with the imported template
            coordinator.goToDrawing(with: template)
        }
    }

    // MARK: - Permissions

    private func checkPermissionAndShowPicker() {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)

        switch status {
        case .notDetermined:
            // Request permission
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { [self] newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        showPhotoPicker = true
                    }
                }
            }
        case .authorized, .limited:
            // Permission granted, show picker
            showPhotoPicker = true
        case .denied, .restricted:
            // Permission denied - user needs to enable in settings
            print("Photo library permission denied. Please enable it in Settings.")
        @unknown default:
            break
        }
    }
}


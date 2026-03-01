import Foundation
import Combine
@preconcurrency import FirebaseDatabase

/// Manager for Firebase Realtime Database operations
@MainActor
class FirebaseManager: ObservableObject {
    static let shared = FirebaseManager()

    @Published var remoteTemplates: [TemplateModel] = []
    @Published var isLoading = false
    @Published var error: Error?

    private let databaseRef: DatabaseReference
    private var observerHandle: DatabaseHandle?

    // Firebase RTD path for templates
    private let templatesPath = "templates"

    private init() {
        // Initialize Firebase Database reference
        self.databaseRef = Database.database().reference()
    }

    // MARK: - Public Methods

    /// Start observing templates from Firebase RTD
    func observeTemplates() {
        isLoading = true
        error = nil

        let templatesRef = databaseRef.child(templatesPath)

        // Observe value changes
        observerHandle = templatesRef.observe(.value) { [weak self] snapshot in
            guard let self = self else { return }

            self.isLoading = false

            guard snapshot.exists() else {
                print("No templates found in Firebase")
                self.remoteTemplates = []
                return
            }

            do {
                // Decode Firebase snapshot
                let templates = try self.decodeTemplates(from: snapshot)
                self.remoteTemplates = templates
                print("Successfully loaded \(templates.count) templates from Firebase")
            } catch {
                print("Failed to decode templates: \(error)")
                self.error = error
                self.remoteTemplates = []
            }
        }
    }

    /// Stop observing templates
    func stopObserving() {
        if let handle = observerHandle {
            databaseRef.child(templatesPath).removeObserver(withHandle: handle)
            observerHandle = nil
        }
    }

    /// Fetch templates once (one-time read)
    func fetchTemplates() async throws -> [TemplateModel] {
        let snapshot = try await databaseRef.child(templatesPath).getData()
        return try decodeTemplates(from: snapshot)
    }

    // MARK: - Private Methods

    private func decodeTemplates(from snapshot: DataSnapshot) throws -> [TemplateModel] {
        var templates: [TemplateModel] = []

        // Firebase returns the data as an array of dictionaries
        // We need to handle the array structure
        if let children = snapshot.children.allObjects as? [DataSnapshot] {
            for childSnapshot in children {
                guard let value = childSnapshot.value as? [String: Any] else {
                    print("Invalid snapshot value format")
                    continue
                }

                // Extract id and name (url)
                guard let idString = value["id"] as? String,
                      let urlString = value["name"] as? String else {
                    print("Missing id or name in template data")
                    continue
                }

                // Create TemplateModel with remote source
                if let id = UUID(uuidString: idString) {
                    let template = TemplateModel(id: id, name: "", bundledAssetName: urlString)
                    templates.append(template)
                }
            }
        }

        return templates
    }

    deinit {
        // Remove observer directly without calling MainActor method
        if let handle = observerHandle {
            databaseRef.child(templatesPath).removeObserver(withHandle: handle)
        }
    }
}

// MARK: - Firebase Decoding Error

enum FirebaseDecodingError: Error, LocalizedError {
    case invalidSnapshotFormat
    case missingRequiredField(String)
    case invalidUUID(String)

    var errorDescription: String? {
        switch self {
        case .invalidSnapshotFormat:
            return "Invalid snapshot format from Firebase"
        case .missingRequiredField(let field):
            return "Missing required field: \(field)"
        case .invalidUUID(let uuidString):
            return "Invalid UUID format: \(uuidString)"
        }
    }
}

import Foundation
import Security

/// Manages secure storage in Keychain for data that should persist across app installations
class KeychainManager {

    // MARK: - Singleton

    static let shared = KeychainManager()

    private init() {}

    // MARK: - Keys

    private enum Keys {
        static let service = "com.sketchy.keychain"
        static let dailyLimitData = "dailyLimitData"
        static let favoriteTemplates = "favoriteTemplates"
    }

    // MARK: - Daily Limit Data

    struct DailyLimitData: Codable {
        let lastDrawingDate: Date?
        let drawingsUsedToday: Int
        let lastResetDate: Date?
        let deviceIdentifier: String

        var isEmpty: Bool {
            return lastDrawingDate == nil && drawingsUsedToday == 0 && lastResetDate == nil
        }
    }

    // MARK: - Public Methods

    /// Saves daily limit data to keychain
    func saveDailyLimitData(_ data: DailyLimitData) {
        guard let encoded = try? JSONEncoder().encode(data) else {
            print("KeychainManager: Failed to encode data")
            return
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.service,
            kSecAttrAccount as String: Keys.dailyLimitData,
            kSecValueData as String: encoded
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("KeychainManager: Failed to save data - \(status)")
        } else {
            print("KeychainManager: Data saved successfully")
        }
    }

    /// Loads daily limit data from keychain
    func loadDailyLimitData() -> DailyLimitData? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.service,
            kSecAttrAccount as String: Keys.dailyLimitData,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let decoded = try? JSONDecoder().decode(DailyLimitData.self, from: data) else {
            print("KeychainManager: No data found or failed to decode")
            return nil
        }

        print("KeychainManager: Data loaded successfully")
        return decoded
    }

    /// Clears daily limit data from keychain
    func clearDailyLimitData() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.service,
            kSecAttrAccount as String: Keys.dailyLimitData
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            print("KeychainManager: Data cleared successfully")
        } else {
            print("KeychainManager: Failed to clear data - \(status)")
        }
    }

    // MARK: - Device Identifier

    /// Gets or creates a unique device identifier stored in keychain
    func getDeviceIdentifier() -> String {
        // Try to load from keychain first
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.service,
            kSecAttrAccount as String: "deviceIdentifier",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess, let data = result as? Data, let identifier = String(data: data, encoding: .utf8) {
            return identifier
        }

        // Create new identifier
        let newIdentifier = UUID().uuidString

        // Save to keychain
        guard let identifierData = newIdentifier.data(using: .utf8) else {
            return newIdentifier
        }

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.service,
            kSecAttrAccount as String: "deviceIdentifier",
            kSecValueData as String: identifierData
        ]

        SecItemAdd(addQuery as CFDictionary, nil)
        return newIdentifier
    }

    // MARK: - Favorite Templates

    /// Saves favorite template IDs to keychain
    func saveFavoriteTemplates(_ templateIDs: [String]) {
        guard let encoded = try? JSONEncoder().encode(templateIDs) else {
            print("KeychainManager: Failed to encode favorite templates")
            return
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.service,
            kSecAttrAccount as String: Keys.favoriteTemplates,
            kSecValueData as String: encoded
        ]

        // Delete existing item first
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("KeychainManager: Failed to save favorite templates - \(status)")
        } else {
            print("KeychainManager: Favorite templates saved (\(templateIDs.count) templates)")
        }
    }

    /// Loads favorite template IDs from keychain
    func loadFavoriteTemplates() -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.service,
            kSecAttrAccount as String: Keys.favoriteTemplates,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            print("KeychainManager: No favorite templates found")
            return []
        }

        print("KeychainManager: Loaded \(decoded.count) favorite templates")
        return decoded
    }

    /// Adds a template to favorites
    func addFavoriteTemplate(_ templateID: String) {
        var favorites = loadFavoriteTemplates()
        if !favorites.contains(templateID) {
            favorites.append(templateID)
            saveFavoriteTemplates(favorites)
        }
    }

    /// Removes a template from favorites
    func removeFavoriteTemplate(_ templateID: String) {
        var favorites = loadFavoriteTemplates()
        favorites.removeAll { $0 == templateID }
        saveFavoriteTemplates(favorites)
    }

    /// Checks if a template is in favorites
    func isTemplateFavorite(_ templateID: String) -> Bool {
        return loadFavoriteTemplates().contains(templateID)
    }

    /// Resets all keychain data (for testing purposes)
    func resetAll() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.service
        ]

        SecItemDelete(query as CFDictionary)
        print("KeychainManager: All data reset")
    }
}

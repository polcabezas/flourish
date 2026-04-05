import Foundation
import Security

// MARK: - Keychain Service
// Stores API keys securely in the macOS Keychain.
// Service: "com.personal.flourish", account: provider rawValue
// Note: Uses the standard macOS keychain (no kSecUseDataProtectionKeychain)
// because the app uses ad-hoc code signing — data protection keychain
// requires a real Apple Developer team certificate.

final class KeychainService {
    static let shared = KeychainService()
    private init() {}

    private let service = "com.personal.flourish"

    // MARK: - Save

    @discardableResult
    func save(_ key: String, for provider: LLMProvider) -> Bool {
        guard let data = key.data(using: .utf8), !key.isEmpty else {
            delete(for: provider)
            return true
        }
        let lookupQuery: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.keychainAccount,
        ]
        // Try updating an existing item first; add if not found.
        let updateStatus = SecItemUpdate(
            lookupQuery as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        if updateStatus == errSecSuccess { return true }
        if updateStatus != errSecItemNotFound { return false }

        let addQuery: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.keychainAccount,
            kSecValueData as String:   data,
        ]
        return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
    }

    // MARK: - Load

    func load(for provider: LLMProvider) -> String? {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.keychainAccount,
            kSecReturnData as String:  true,
            kSecMatchLimit as String:  kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8),
              !key.isEmpty else { return nil }
        return key
    }

    // MARK: - Delete

    @discardableResult
    func delete(for provider: LLMProvider) -> Bool {
        let query: [String: Any] = [
            kSecClass as String:       kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.keychainAccount,
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Check Presence

    func hasKey(for provider: LLMProvider) -> Bool {
        load(for: provider) != nil
    }
}

import Foundation
import KeychainAccess

/// Manages secure storage of sensitive data in macOS Keychain.
public final class KeychainManager {
    public static let shared = KeychainManager()

    private let keychain: Keychain

    private init() {
        keychain = Keychain(service: "com.aimactools")
            .accessibility(.whenUnlocked)
            .synchronizable(false)
    }

    /// Creates a manager for a specific service identifier.
    /// - Parameter service: Bundle identifier or service name
    public init(service: String) {
        keychain = Keychain(service: service)
            .accessibility(.whenUnlocked)
            .synchronizable(false)
    }

    // MARK: - OpenAI API Key

    private let openAIKeyName = "openai_api_key"

    /// Saves the OpenAI API key securely.
    /// - Parameter key: The API key to store
    public func saveOpenAIKey(_ key: String) throws {
        try keychain.set(key, key: openAIKeyName)
    }

    /// Retrieves the stored OpenAI API key.
    /// - Returns: The API key, or nil if not set
    public func getOpenAIKey() -> String? {
        try? keychain.get(openAIKeyName)
    }

    /// Deletes the stored OpenAI API key.
    public func deleteOpenAIKey() throws {
        try keychain.remove(openAIKeyName)
    }

    /// Whether an OpenAI API key is stored.
    public var hasOpenAIKey: Bool {
        getOpenAIKey() != nil
    }

    // MARK: - Generic Key Storage

    /// Saves a value securely.
    /// - Parameters:
    ///   - value: The string value to store
    ///   - key: The key name
    public func save(_ value: String, forKey key: String) throws {
        try keychain.set(value, key: key)
    }

    /// Retrieves a stored value.
    /// - Parameter key: The key name
    /// - Returns: The stored value, or nil if not found
    public func get(forKey key: String) -> String? {
        try? keychain.get(key)
    }

    /// Deletes a stored value.
    /// - Parameter key: The key name
    public func delete(forKey key: String) throws {
        try keychain.remove(key)
    }
}

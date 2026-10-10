import Foundation

/// High-level credential manager coordinating token persistence across UserPreferences, macOS Keychain, and shared container storage.
public enum TokenStorage {
    private static var groupDefaults: UserDefaults {
        UserDefaults(suiteName: "group.com.gitstreak") ?? .standard
    }
    private static let tokenKey = "github_pat"
    private static let lock = NSLock()
    nonisolated(unsafe) private static var inMemoryCache: String?

    private static var tokenFileURL: URL {
        return SharedContainer.url.appendingPathComponent(".token_auth")
    }

    /// Saves the GitHub access token securely into macOS Keychain, App Group container, and persistent container file.
    /// - Parameter token: The GitHub Personal Access Token or OAuth token.
    public static func saveToken(_ token: String) {
        let cleanToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanToken.isEmpty else { return }

        lock.lock()
        inMemoryCache = cleanToken
        lock.unlock()

        // 1. Save to Keychain
        try? KeychainService.save(token: cleanToken, forKey: tokenKey)

        // 2. Save to App Group UserDefaults
        groupDefaults.set(cleanToken, forKey: tokenKey)
        groupDefaults.synchronize()

        // Clean up any legacy plaintext token file if it exists
        if FileManager.default.fileExists(atPath: tokenFileURL.path) {
            try? FileManager.default.removeItem(at: tokenFileURL)
        }
    }

    /// Loads the stored GitHub access token with self-healing automatic sync.
    /// - Returns: The access token string, or `nil` if none exists.
    public static func loadToken() -> String? {
        lock.lock()
        if let cached = inMemoryCache, !cached.isEmpty {
            lock.unlock()
            return cached
        }
        lock.unlock()

        var foundToken: String?

        // 1. Try Keychain
        if let token = KeychainService.load(forKey: tokenKey), !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            foundToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // 2. Try App Group UserDefaults Fallback
        if foundToken == nil, let token = groupDefaults.string(forKey: tokenKey), !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            foundToken = token.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // 3. Try Legacy Shared Container File Fallback (migrate and remove)
        if foundToken == nil,
           FileManager.default.fileExists(atPath: tokenFileURL.path),
           let data = try? Data(contentsOf: tokenFileURL),
           let rawToken = String(data: data, encoding: .utf8),
           !rawToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            foundToken = rawToken.trimmingCharacters(in: .whitespacesAndNewlines)
            try? FileManager.default.removeItem(at: tokenFileURL)
        }

        // Self-Healing Sync: If token was recovered from fallback layers, re-populate Keychain & Group Defaults
        if let token = foundToken {
            lock.lock()
            inMemoryCache = token
            lock.unlock()

            // Silently ensure secure storage layers stay in sync
            try? KeychainService.save(token: token, forKey: tokenKey)
            groupDefaults.set(token, forKey: tokenKey)
            groupDefaults.synchronize()
            if FileManager.default.fileExists(atPath: tokenFileURL.path) {
                try? FileManager.default.removeItem(at: tokenFileURL)
            }
        }

        return foundToken
    }

    /// Clears the stored access token completely from macOS Keychain, App Group storage, and container file.
    public static func clearToken() {
        lock.lock()
        inMemoryCache = nil
        lock.unlock()

        try? KeychainService.delete(forKey: tokenKey)
        groupDefaults.removeObject(forKey: tokenKey)
        groupDefaults.synchronize()
        if FileManager.default.fileExists(atPath: tokenFileURL.path) {
            try? FileManager.default.removeItem(at: tokenFileURL)
        }
    }
}

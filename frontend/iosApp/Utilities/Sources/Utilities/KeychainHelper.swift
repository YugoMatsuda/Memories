import Foundation
import KeychainAccess

public enum KeychainHelper {
    public enum Key: String {
        case accessToken = "accessToken"
        case userId = "userId"
    }

    static let keychain: @Sendable () -> Keychain = {
        return Keychain(service: "com.example.memoriesapp.MemoriesApp")
    }

    public static func get(_ key: Key) -> String? {
        keychain()[key.rawValue]
    }

    public static func set(_ value: String, for key: Key) {
        keychain()[key.rawValue] = value
    }

    public static func remove(_ key: Key) {
        try? keychain().remove(key.rawValue)
    }

    public static func clear() {
        try? keychain().removeAll()
    }
}

// Copyright © 2026 Easydict contributors. GPL-3.0.

import Foundation
import Security

/// API keys are isolated from upstream Easydict and never saved in preferences or logs.
enum CredentialStore {
    private static let service = "org.easydict.focused.api"

    static func read(channel: APIChannel) throws -> String {
        var query = baseQuery(channel: channel)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return "" }
        guard status == errSecSuccess, let data = item as? Data else {
            throw CredentialError(status: status)
        }
        return String(data: data, encoding: .utf8) ?? ""
    }

    static func save(_ key: String, channel: APIChannel) throws {
        let query = baseQuery(channel: channel)
        let key = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if key.isEmpty {
            let status = SecItemDelete(query as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw CredentialError(status: status)
            }
            return
        }
        let values = [kSecValueData as String: Data(key.utf8)]
        let updateStatus = SecItemUpdate(query as CFDictionary, values as CFDictionary)
        if updateStatus == errSecItemNotFound {
            var item = query
            item.merge(values) { _, new in new }
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            let status = SecItemAdd(item as CFDictionary, nil)
            guard status == errSecSuccess else { throw CredentialError(status: status) }
        } else if updateStatus != errSecSuccess {
            throw CredentialError(status: updateStatus)
        }
    }

    private static func baseQuery(channel: APIChannel) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: channel.rawValue,
        ]
    }
}

private struct CredentialError: LocalizedError {
    let status: OSStatus

    var errorDescription: String? {
        AppStrings.text("focused.error.keychain") + " (\(status))"
    }
}

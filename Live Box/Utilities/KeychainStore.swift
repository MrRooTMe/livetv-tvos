import Foundation
import Security

final class KeychainStore {
    static let shared = KeychainStore(service: "LiveBoxAPI$$$", account: "LiveBoxfortvOS")

    private let service: String
    private let account: String

    init(service: String, account: String) {
        self.service = service
        self.account = account
    }

    var activationCode: String? {
        get {
            guard let data = readValue() else { return nil }
            return String(data: data, encoding: .utf8)
        }
        set {
            if let value = newValue {
                save(value: value)
            } else {
                removeActivationCode()
            }
        }
    }

    func setActivationCode(_ code: String) {
        activationCode = code
    }

    func removeActivationCode() {
        let query = baseQuery()
        SecItemDelete(query as CFDictionary)
    }

    private func save(value: String) {
        let encodedValue = Data(value.utf8)
        var query = baseQuery()
        let attributes: [String: Any] = [kSecValueData as String: encodedValue]
        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status == errSecItemNotFound {
            query[kSecValueData as String] = encodedValue
            status = SecItemAdd(query as CFDictionary, nil)
        }

        if status != errSecSuccess {
            NSLog("Failed to store value in keychain with status: %d", status)
        }
    }

    private func readValue() -> Data? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
    }
}

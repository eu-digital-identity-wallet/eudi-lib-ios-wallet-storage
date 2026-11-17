import Foundation
import Security
import Testing
@testable import WalletStorage

/// Portable tests of the Security call contract; all add/update calls are injected.
/// They do not access a device Keychain or require Keychain entitlements.
@Suite("Keychain overwrite")
struct KeychainOverwriteTests {
    @Test("New items include their identity and attributes", arguments: [false, true])
    func addsNewItem(allowOverwrite: Bool) throws {
        let attributes: [String: Any] = [
            kSecValueData as String: Data("new-document".utf8),
            kSecAttrAccessible as String: kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        ]
        var adds = 0
        var updates = 0
        try save(attributes: attributes, allowOverwrite: allowOverwrite, add: { item in
            adds += 1
            let item = item as! [String: Any]
            #expect(item[kSecAttrAccount as String] as? String == "document-id")
            #expect(item[kSecAttrAccessGroup as String] as? String == "test-group")
            #expect(item[kSecUseDataProtectionKeychain as String] as? Bool == true)
            #expect(item[kSecValueData as String] as? Data == Data("new-document".utf8))
            #expect(item[kSecAttrAccessible as String] as? String == kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly as String)
            return errSecSuccess
        }, update: { _, _ in
            updates += 1
            return errSecSuccess
        })
        #expect(adds == 1)
        #expect(updates == 0)
    }

    @Test("Changed stored attributes do not become overwrite search criteria", arguments: [
        kSecAttrDescription as String, kSecAttrLabel as String, kSecAttrComment as String
    ])
    func overwritesByIdentity(changedAttribute: String) throws {
        let attributes: [String: Any] = [
            kSecValueData as String: Data("replacement".utf8),
            changedAttribute: "new-attribute-value",
            kSecAttrAccessible as String: kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        ]
        var adds = 0
        var updates = 0
        try save(attributes: attributes, allowOverwrite: true, add: { item in
            adds += 1
            let item = item as! [String: Any]
            #expect(item[changedAttribute] as? String == "new-attribute-value")
            return errSecDuplicateItem
        }, update: { query, changes in
            updates += 1
            let query = query as! [String: Any]
            // The existing item has "old-attribute-value". Including the new
            // description, label or comment in the search cannot match it.
            if let filter = query[changedAttribute] as? String, filter != "old-attribute-value" {
                return errSecItemNotFound
            }
            expectStableIdentity(query)
            let changes = changes as! [String: Any]
            #expect(changes[changedAttribute] as? String == "new-attribute-value")
            #expect(changes[kSecValueData as String] as? Data == Data("replacement".utf8))
            #expect(changes[kSecAttrAccessible as String] as? String == kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly as String)
            #expect(changes[kSecAttrAccount as String] == nil)
            #expect(changes[kSecAttrAccessGroup as String] == nil)
            return errSecSuccess
        })
        #expect(adds == 1)
        #expect(updates == 1)
    }

    @Test("Duplicate items are refused when overwriting is disabled")
    func refusesDuplicate() {
        var adds = 0
        var updates = 0
        expectStatus(errSecDuplicateItem) {
            try save(attributes: [:], allowOverwrite: false, add: { _ in
                adds += 1
                return errSecDuplicateItem
            }, update: { _, _ in
                updates += 1
                return errSecSuccess
            })
        }
        #expect(adds == 1)
        #expect(updates == 0)
    }

    @Test("Add errors do not trigger an update", arguments: [errSecAuthFailed, errSecParam, errSecNotAvailable])
    func propagatesAddFailure(status: OSStatus) {
        var updates = 0
        expectStatus(status) {
            try save(attributes: [:], allowOverwrite: true, add: { _ in status }, update: { _, _ in
                updates += 1
                return errSecSuccess
            })
        }
        #expect(updates == 0)
    }

    @Test("Update errors are propagated without retrying the add", arguments: [errSecItemNotFound, errSecAuthFailed, errSecInteractionNotAllowed])
    func propagatesUpdateFailure(status: OSStatus) {
        var adds = 0
        var updates = 0
        expectStatus(status) {
            try save(attributes: [:], allowOverwrite: true, add: { _ in
                adds += 1
                return errSecDuplicateItem
            }, update: { _, _ in
                updates += 1
                return status
            })
        }
        #expect(adds == 1)
        #expect(updates == 1)
    }

    private func save(
        attributes: [String: Any], allowOverwrite: Bool,
        add: (CFDictionary) -> OSStatus,
        update: (CFDictionary, CFDictionary) -> OSStatus
    ) throws {
        try KeyChainStorageService.saveDocumentData(
            serviceName: "keychain-overwrite-tests", accessGroup: "test-group", id: "document-id",
            status: .issued, dataType: .docPresent,
            setDictValues: { $0.merge(attributes) { _, new in new } },
            allowOverwrite: allowOverwrite, add: add, update: update
        )
    }

    private func expectStableIdentity(_ query: [String: Any]) {
        #expect(Set(query.keys) == Set([
            kSecClass as String, kSecAttrService as String, kSecAttrAccount as String,
            kSecAttrAccessGroup as String, kSecUseDataProtectionKeychain as String
        ]))
        #expect(query[kSecClass as String] as? String == kSecClassGenericPassword as String)
        #expect(query[kSecAttrService as String] as? String == "keychain-overwrite-tests:pdoc:issued")
        #expect(query[kSecAttrAccount as String] as? String == "document-id")
        #expect(query[kSecAttrAccessGroup as String] as? String == "test-group")
        #expect(query[kSecUseDataProtectionKeychain as String] as? Bool == true)
    }

    private func expectStatus(_ expected: OSStatus, _ operation: () throws -> Void) {
        do {
            try operation()
            Issue.record("Expected StorageError with status \(expected)")
        } catch let error as StorageError {
            #expect(error.code == Int(expected))
        } catch {
            Issue.record("Expected StorageError, got \(error)")
        }
    }
}

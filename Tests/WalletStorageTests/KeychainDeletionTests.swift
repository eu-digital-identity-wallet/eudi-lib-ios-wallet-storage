import CryptoKit
import Foundation
import MdocDataModel18013
import Security
import os
import Testing
@testable import WalletStorage

@Suite("Keychain deletion ordering")
struct KeychainDeletionTests {
    @Test("Invalid independent key-store service leaves the placeholder available for retry")
    func invalidKeyStore() async throws {
        let documentService = "documents"
        let storage = KeyChainStorageService(serviceName: documentService)
        let area = DeletionSecureArea(storage: KeyChainSecureKeyStorage(serviceName: "keys:invalid", accessGroup: nil))
        let deleted = OSAllocatedUnfairLock(initialState: [String]())
        let info = DocKeyInfo(secureAreaName: DeletionSecureArea.name, batchSize: 1, credentialPolicy: .rotateUse)
        for _ in 0..<2 {
            do {
                try await storage.deleteDocumentHelper(
                    id: "document", dki: info, status: .issued,
                    resolveSecureArea: { _ in area },
                    deleteData: { id, type in
                        // The document store is independently valid; deletion would succeed.
                        _ = try KeyChainStorageService.makeQuery(
                            serviceName: documentService, accessGroup: nil, id: id,
                            bForSave: false, status: .issued, dataType: type
                        )
                        deleted.withLock { $0.append(id) }
                    }
                )
                Issue.record("Expected key-store service validation to fail")
            } catch let error as StorageError {
                #expect(error.code == Int(errSecParam))
            }
            #expect(deleted.withLock { $0.isEmpty })
        }
    }

    @Test("Missing document key metadata still allows placeholder deletion", arguments: DocumentStatus.allCases)
    func missingMetadata(status: DocumentStatus) async throws {
        let storage = KeyChainStorageService(serviceName: "documents")
        let deleted = OSAllocatedUnfairLock(initialState: [String]())
        try await storage.deleteDocumentHelper(
            id: "document", dki: nil, status: status,
            resolveSecureArea: { _ in
                Issue.record("No secure area should be resolved without key metadata")
                throw StorageError(description: "Unexpected lookup")
            },
            deleteData: { id, type in
                #expect(type == .docPresent)
                deleted.withLock { $0.append(id) }
            }
        )
        #expect(deleted.withLock { $0 } == ["document"])
    }

    @Test("Successful metadata read allows document and key cleanup")
    func successfulDeletion() async throws {
        let keyStore = InMemorySecureKeyStorage()
        let batch = KeyBatchInfo(keyOptions: nil, usedCounts: [0], credentialPolicy: .rotateUse)
        try await keyStore.writeKeyInfo(id: "document", dict: [kSecValueData as String: try #require(batch.toData())])
        try await keyStore.writeKeyDataBatch(id: "document", startIndex: 0, dicts: [["key": Data([1])]], keyOptions: nil)
        let area = DeletionSecureArea(storage: keyStore)
        let storage = KeyChainStorageService(serviceName: "documents")
        let deleted = OSAllocatedUnfairLock(initialState: [String]())
        try await storage.deleteDocumentHelper(
            id: "document", dki: DocKeyInfo(secureAreaName: DeletionSecureArea.name, batchSize: 1, credentialPolicy: .rotateUse), status: .issued,
            resolveSecureArea: { _ in area },
            deleteData: { id, type in deleted.withLock { $0.append("\(id):\(type.rawValue)") } }
        )
        #expect(deleted.withLock { $0 } == ["document:pdoc", "document_0:sdoc"])
        #expect(await keyStore.getAllKeyInfoIds().isEmpty)
        #expect(await keyStore.getAllKeyDataKeys().isEmpty)
    }
}

private actor DeletionSecureArea: SecureArea {
    static let supportedEcCurves: [CoseEcCurve] = [.P256]
    let storage: any SecureKeyStorage
    init(storage: any SecureKeyStorage) { self.storage = storage }
    nonisolated static func create(storage: any SecureKeyStorage) -> Self { Self(storage: storage) }
    func getStorage() async -> any SecureKeyStorage { storage }
    func deleteKeyBatch(id: String, startIndex: Int, batchSize: Int) async throws {
        try await storage.deleteKeyBatch(id: id, startIndex: startIndex, batchSize: batchSize)
    }
    func deleteKeyInfo(id: String) async throws { try await storage.deleteKeyInfo(id: id) }
    func createKeyBatch(id: String, credentialOptions: CredentialOptions, keyOptions: KeyOptions?) async throws -> [CoseKey] { fatalError("Unused") }
    func getPublicKey(id: String, index: Int, curve: CoseEcCurve) async throws -> CoseKey { fatalError("Unused") }
    func signature(id: String, index: Int, algorithm: SigningAlgorithm, dataToSign: Data, unlockData: Data?, authenticationContext: ThreadSafeAuthContext) async throws -> Data { fatalError("Unused") }
    func keyAgreement(id: String, index: Int, publicKey: CoseKey, unlockData: Data?, authenticationContext: ThreadSafeAuthContext) async throws -> SharedSecret { fatalError("Unused") }
}

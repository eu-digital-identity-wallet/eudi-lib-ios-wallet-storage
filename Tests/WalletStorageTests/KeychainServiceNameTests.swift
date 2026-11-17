import Foundation
import Security
import Testing
@testable import WalletStorage

@Suite("Keychain service name validation")
struct KeychainServiceNameTests {
    @Test(arguments: [":wallet", "wallet:", "wallet:sdoc:issued", ":"])
    func rejectsColon(service: String) {
        expectInvalidService {
            _ = try KeyChainStorageService.loadData(
                serviceName: service, accessGroup: nil, id: "document",
                status: .issued, dataToLoadType: .doc
            )
        }
        expectInvalidService {
            try KeyChainStorageService.deleteDocumentData(
                serviceName: service, accessGroup: nil, id: "document",
                docStatus: .issued, dataType: .doc
            )
        }
        expectInvalidService {
            try KeyChainStorageService.saveDocumentData(
                serviceName: service, accessGroup: nil, id: "document",
                status: .issued, dataType: .doc,
                setDictValues: { _ in Issue.record("Invalid service reached attribute construction") },
                allowOverwrite: true,
                add: { _ in Issue.record("Invalid service reached add"); return errSecSuccess },
                update: { _, _ in Issue.record("Invalid service reached update"); return errSecSuccess }
            )
        }
    }

    @Test(arguments: ["wallet", "wallet-name", "wallet_name"])
    func acceptsValidService(service: String) throws {
        for type in SavedKeyChainDataType.allCases {
            for status in DocumentStatus.allCases {
                let query = try KeyChainStorageService.makeQuery(
                    serviceName: service, accessGroup: nil, id: "document_0",
                    bForSave: false, status: status, dataType: type
                )
                #expect(query[kSecAttrService as String] as? String == "\(service):\(type.rawValue):\(status.rawValue)")
                #expect(query[kSecAttrAccount as String] as? String == "document_0")
            }
        }
    }

    private func expectInvalidService(_ operation: () throws -> Void) {
        do {
            try operation()
            Issue.record("Expected invalid service name to be rejected")
        } catch let error as StorageError {
            #expect(error.code == Int(errSecParam))
            #expect(error.errorDescription == "Service name must not contain a colon (:).")
        } catch {
            Issue.record("Expected StorageError, got \(error)")
        }
    }
}

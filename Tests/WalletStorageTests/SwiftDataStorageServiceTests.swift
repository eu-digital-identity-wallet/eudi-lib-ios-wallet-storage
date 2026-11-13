import Foundation
import Testing
@testable import WalletStorage
import SwiftData

@Suite("SwiftData Storage Tests")
struct SwiftDataStorageServiceTests {
	
	@Test("Save and load a document")
	func saveAndLoadDocument() async throws {
		let storage = try SwiftDataStorageService(isStoredInMemoryOnly: true)
		let data = "SwiftData document".data(using: .utf8)!
		let metadata = "SwiftData metadata".data(using: .utf8)
		let document = Document(
			id: "swiftdata-doc",
			docType: "org.iso.18013.5.1.mDL",
			docDataFormat: .cbor,
			data: data,
			docKeyInfo: nil,
			createdAt: Date(),
			metadata: metadata,
			displayName: "SwiftData Document",
			status: .issued
		)
		
		try await storage.saveDocument(document, batch: nil, allowOverwrite: true)
		
		let loaded = try await storage.loadDocument(id: "swiftdata-doc", status: .issued)
		#expect(loaded?.id == "swiftdata-doc")
		#expect(loaded?.data == data)
		#expect(loaded?.metadata == metadata)
	}
	
	@Test("Prevent overwrite when requested")
	func preventOverwrite() async throws {
		let storage = try SwiftDataStorageService(isStoredInMemoryOnly: true)
		let document = Document(
			id: "swiftdata-no-overwrite",
			docType: "org.iso.18013.5.1.mDL",
			docDataFormat: .cbor,
			data: Data(),
			docKeyInfo: nil,
			createdAt: Date(),
			metadata: nil,
			displayName: nil,
			status: .issued
		)
		
		try await storage.saveDocument(document, batch: nil, allowOverwrite: false)
		
		await #expect(throws: StorageError.self) {
			try await storage.saveDocument(document, batch: nil, allowOverwrite: false)
		}
	}
	
	@Test("Delete only documents with requested status")
	func deleteDocumentsWithStatus() async throws {
		let storage = try SwiftDataStorageService(isStoredInMemoryOnly: true)
		let issued = Document(
			id: "swiftdata-issued",
			docType: "org.iso.18013.5.1.mDL",
			docDataFormat: .cbor,
			data: Data(),
			docKeyInfo: nil,
			createdAt: Date(),
			metadata: nil,
			displayName: nil,
			status: .issued
		)
		let deferred = Document(
			id: "swiftdata-deferred",
			docType: "org.iso.18013.5.1.mDL",
			docDataFormat: .cbor,
			data: Data(),
			docKeyInfo: nil,
			createdAt: Date(),
			metadata: nil,
			displayName: nil,
			status: .deferred
		)
		
		try await storage.saveDocument(issued, batch: nil, allowOverwrite: true)
		try await storage.saveDocument(deferred, batch: nil, allowOverwrite: true)
		try await storage.deleteDocuments(status: .issued)
		
		#expect(try await storage.loadDocuments(status: .issued) == nil)
		#expect(try await storage.loadDocuments(status: .deferred)?.map(\.id) == ["swiftdata-deferred"])
	}
}

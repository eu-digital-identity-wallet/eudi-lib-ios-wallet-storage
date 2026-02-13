import Testing
import Foundation
@testable import WalletStorage
import MdocDataModel18013

@Suite("Document Storage Tests")
struct DocumentStorageTests {
	
	let storage: InMemoryDataStorageService
	
	init() {
		storage = InMemoryDataStorageService()
	}
	
	// MARK: - Save Tests
	
	@Test("Save a single document successfully")
	func testSaveDocument() async throws {
		// Given
		let testData = "Test Document Data".data(using: .utf8)!
		let metadata = "Test Metadata".data(using: .utf8)
		let document = WalletStorage.Document(
			id: "test-doc-1",
			docType: "org.iso.18013.5.1.mDL",
			docDataFormat: .cbor,
			data: testData,
			docKeyInfo: nil,
			createdAt: Date(),
			metadata: metadata,
			displayName: "Test Document",
			status: .issued
		)
		
		// When
		try await storage.saveDocument(document, batch: nil, allowOverwrite: true)
		
		// Then
		let loaded = try await storage.loadDocument(id: "test-doc-1", status: .issued)
		#expect(loaded != nil)
		#expect(loaded?.id == "test-doc-1")
		#expect(loaded?.docType == "org.iso.18013.5.1.mDL")
		#expect(loaded?.data == testData)
	}
	
	@Test("Save document with batch credentials")
	func testSaveDocumentWithBatch() async throws {
		// Given
		let mainData = "Main Document".data(using: .utf8)!
		let batchData1 = "Batch Credential 1".data(using: .utf8)!
		let batchData2 = "Batch Credential 2".data(using: .utf8)!
		
		let mainDoc = WalletStorage.Document(
			id: "batch-doc-1",
			docType: "org.iso.18013.5.1.mDL",
			docDataFormat: .cbor,
			data: mainData,
			docKeyInfo: nil,
			createdAt: Date(),
			metadata: nil,
			displayName: "Batch Document",
			status: .issued
		)
		
		let batchDocs = [
			WalletStorage.Document(
				id: "batch-doc-1",
				docType: "org.iso.18013.5.1.mDL",
				docDataFormat: .cbor,
				data: batchData1,
				docKeyInfo: nil,
				createdAt: Date(),
				metadata: nil,
				displayName: "Batch 1",
				status: .issued
			),
			WalletStorage.Document(
				id: "batch-doc-1",
				docType: "org.iso.18013.5.1.mDL",
				docDataFormat: .cbor,
				data: batchData2,
				docKeyInfo: nil,
				createdAt: Date(),
				metadata: nil,
				displayName: "Batch 2",
				status: .issued
			)
		]
		
		// When
		try await storage.saveDocument(mainDoc, batch: batchDocs, allowOverwrite: true)
		
		// Then
		let loaded = try await storage.loadDocument(id: "batch-doc-1", status: .issued)
		#expect(loaded != nil)
		#expect(loaded?.id == "batch-doc-1")
	}
	
	@Test("Save document with different statuses")
	func testSaveDocumentWithDifferentStatuses() async throws {
		let testData = "Test Data".data(using: .utf8)!
		
		// Save issued document
		let issuedDoc = WalletStorage.Document(
			id: "status-doc-1",
			docType: "org.iso.18013.5.1.mDL",
			docDataFormat: .cbor,
			data: testData,
			docKeyInfo: nil,
			createdAt: Date(),
			metadata: nil,
			displayName: "Issued",
			status: .issued
		)
		try await storage.saveDocument(issuedDoc, batch: nil, allowOverwrite: true)
		
		// Save deferred document
		let deferredDoc = WalletStorage.Document(
			id: "status-doc-2",
			docType: "org.iso.18013.5.1.mDL",
			docDataFormat: .cbor,
			data: testData,
			docKeyInfo: nil,
			createdAt: Date(),
			metadata: nil,
			displayName: "Deferred",
			status: .deferred
		)
		try await storage.saveDocument(deferredDoc, batch: nil, allowOverwrite: true)
		
		// Save pending document
		let pendingDoc = WalletStorage.Document(
			id: "status-doc-3",
			docType: "org.iso.18013.5.1.mDL",
			docDataFormat: .cbor,
			data: testData,
			docKeyInfo: nil,
			createdAt: Date(),
			metadata: nil,
			displayName: "Pending",
			status: .pending
		)
		try await storage.saveDocument(pendingDoc, batch: nil, allowOverwrite: true)
		
		// Verify each can be loaded
		let loadedIssued = try await storage.loadDocument(id: "status-doc-1", status: .issued)
		#expect(loadedIssued?.status == .issued)
		
		let loadedDeferred = try await storage.loadDocument(id: "status-doc-2", status: .deferred)
		#expect(loadedDeferred?.status == .deferred)
		
		let loadedPending = try await storage.loadDocument(id: "status-doc-3", status: .pending)
		#expect(loadedPending?.status == .pending)
	}
	
	@Test("Prevent overwrite when not allowed")
	func testPreventOverwrite() async throws {
		// Given
		let testData = "Original Data".data(using: .utf8)!
		let document = WalletStorage.Document(
			id: "no-overwrite-doc",
			docType: "org.iso.18013.5.1.mDL",
			docDataFormat: .cbor,
			data: testData,
			docKeyInfo: nil,
			createdAt: Date(),
			metadata: nil,
			displayName: "Original",
			status: .issued
		)
		
		// When - save first time
		try await storage.saveDocument(document, batch: nil, allowOverwrite: false)
		
		// Then - attempt to save again with allowOverwrite = false should throw
		await #expect(throws: StorageError.self) {
			try await storage.saveDocument(document, batch: nil, allowOverwrite: false)
		}
	}
	
	// MARK: - Query Tests
	
	@Test("Load document by id and status")
	func testLoadDocumentByIdAndStatus() async throws {
		// Given
		let testData = "Query Test Data".data(using: .utf8)!
		let document = WalletStorage.Document(
			id: "query-doc-1",
			docType: "org.iso.18013.5.1.mDL",
			docDataFormat: .cbor,
			data: testData,
			docKeyInfo: nil,
			createdAt: Date(),
			metadata: nil,
			displayName: "Query Test",
			status: .issued
		)
		try await storage.saveDocument(document, batch: nil, allowOverwrite: true)
		
		// When
		let loaded = try await storage.loadDocument(id: "query-doc-1", status: .issued)
		
		// Then
		#expect(loaded != nil)
		#expect(loaded?.id == "query-doc-1")
		#expect(loaded?.data == testData)
		#expect(loaded?.docType == "org.iso.18013.5.1.mDL")
		#expect(loaded?.status == .issued)
	}
	
	@Test("Load non-existent document returns nil")
	func testLoadNonExistentDocument() async throws {
		// When
		let loaded = try await storage.loadDocument(id: "non-existent", status: .issued)
		
		// Then
		#expect(loaded == nil)
	}
	
	@Test("Load all documents with specific status")
	func testLoadAllDocumentsWithStatus() async throws {
		// Given - save multiple documents with issued status
		for i in 1...3 {
			let doc = WalletStorage.Document(
				id: "multi-doc-\(i)",
				docType: "org.iso.18013.5.1.mDL",
				docDataFormat: .cbor,
				data: "Data \(i)".data(using: .utf8)!,
				docKeyInfo: nil,
				createdAt: Date(),
				metadata: nil,
				displayName: "Document \(i)",
				status: .issued
			)
			try await storage.saveDocument(doc, batch: nil, allowOverwrite: true)
		}
		
		// Save one deferred document
		let deferredDoc = WalletStorage.Document(
			id: "deferred-doc",
			docType: "org.iso.18013.5.1.mDL",
			docDataFormat: .cbor,
			data: "Deferred Data".data(using: .utf8)!,
			docKeyInfo: nil,
			createdAt: Date(),
			metadata: nil,
			displayName: "Deferred",
			status: .deferred
		)
		try await storage.saveDocument(deferredDoc, batch: nil, allowOverwrite: true)
		
		// When
		let issuedDocs = try await storage.loadDocuments(status: .issued)
		let deferredDocs = try await storage.loadDocuments(status: .deferred)
		
		// Then
		#expect(issuedDocs?.count == 3)
		#expect(deferredDocs?.count == 1)
	}
	
	@Test("Load documents returns nil when none exist")
	func testLoadDocumentsReturnsNilWhenEmpty() async throws {
		// When
		let docs = try await storage.loadDocuments(status: .pending)
		
		// Then
		#expect(docs == nil)
	}
	
	// MARK: - Delete Tests
	
	@Test("Delete document by id and status")
	func testDeleteDocument() async throws {
		// Given
		let testData = "Delete Test Data".data(using: .utf8)!
		let document = WalletStorage.Document(
			id: "delete-doc-1",
			docType: "org.iso.18013.5.1.mDL",
			docDataFormat: .cbor,
			data: testData,
			docKeyInfo: nil,
			createdAt: Date(),
			metadata: nil,
			displayName: "Delete Test",
			status: .issued
		)
		try await storage.saveDocument(document, batch: nil, allowOverwrite: true)
		
		// Verify it exists
		let beforeDelete = try await storage.loadDocument(id: "delete-doc-1", status: .issued)
		#expect(beforeDelete != nil)
		
		// When
		try await storage.deleteDocument(id: "delete-doc-1", status: .issued)
		
		// Then
		let afterDelete = try await storage.loadDocument(id: "delete-doc-1", status: .issued)
		#expect(afterDelete == nil)
	}
	
	@Test("Delete non-existent document throws error")
	func testDeleteNonExistentDocument() async throws {
		// When/Then
		await #expect(throws: StorageError.self) {
			try await storage.deleteDocument(id: "non-existent", status: .issued)
		}
	}
	
	@Test("Delete all documents with specific status")
	func testDeleteAllDocumentsWithStatus() async throws {
		// Given - save multiple documents
		for i in 1...3 {
			let doc = WalletStorage.Document(
				id: "delete-all-\(i)",
				docType: "org.iso.18013.5.1.mDL",
				docDataFormat: .cbor,
				data: "Data \(i)".data(using: .utf8)!,
				docKeyInfo: nil,
				createdAt: Date(),
				metadata: nil,
				displayName: "Document \(i)",
				status: .issued
			)
			try await storage.saveDocument(doc, batch: nil, allowOverwrite: true)
		}
		
		// Save one deferred document that should NOT be deleted
		let deferredDoc = WalletStorage.Document(
			id: "keep-this",
			docType: "org.iso.18013.5.1.mDL",
			docDataFormat: .cbor,
			data: "Keep Me".data(using: .utf8)!,
			docKeyInfo: nil,
			createdAt: Date(),
			metadata: nil,
			displayName: "Keep",
			status: .deferred
		)
		try await storage.saveDocument(deferredDoc, batch: nil, allowOverwrite: true)
		
		// When
		try await storage.deleteDocuments(status: .issued)
		
		// Then
		let issuedDocs = try await storage.loadDocuments(status: .issued)
		let deferredDocs = try await storage.loadDocuments(status: .deferred)
		
		#expect(issuedDocs == nil)
		#expect(deferredDocs?.count == 1)
		#expect(deferredDocs?.first?.id == "keep-this")
	}
	
	@Test("Delete document credential at index")
	func testDeleteDocumentCredential() async throws {
		// Given
		let mainData = "Main".data(using: .utf8)!
		let batch = [
			WalletStorage.Document(
				id: "cred-doc",
				docType: "org.iso.18013.5.1.mDL",
				docDataFormat: .cbor,
				data: "Cred 1".data(using: .utf8)!,
				docKeyInfo: nil,
				createdAt: Date(),
				metadata: nil,
				displayName: "Cred 1",
				status: .issued
			)
		]
		
		let mainDoc = WalletStorage.Document(
			id: "cred-doc",
			docType: "org.iso.18013.5.1.mDL",
			docDataFormat: .cbor,
			data: mainData,
			docKeyInfo: nil,
			createdAt: Date(),
			metadata: nil,
			displayName: "Main",
			status: .issued
		)
		
		try await storage.saveDocument(mainDoc, batch: batch, allowOverwrite: true)
		
		// When
		try await storage.deleteDocumentCredential(id: "cred-doc", index: 0)
		
		// Then - credential should be deleted but main document should remain
		let main = try await storage.loadDocument(id: "cred-doc", status: .issued)
		#expect(main != nil)
	}
	
	@Test("Delete non-existent credential throws error")
	func testDeleteNonExistentCredential() async throws {
		// When/Then
		await #expect(throws: StorageError.self) {
			try await storage.deleteDocumentCredential(id: "non-existent", index: 0)
		}
	}
	
	// MARK: - Document Properties Tests
	
	@Test("Document with metadata is preserved")
	func testDocumentMetadataPreserved() async throws {
		// Given
		let metadata = "Important Metadata".data(using: .utf8)!
		let document = WalletStorage.Document(
			id: "metadata-doc",
			docType: "org.iso.18013.5.1.mDL",
			docDataFormat: .cbor,
			data: "Data".data(using: .utf8)!,
			docKeyInfo: nil,
			createdAt: Date(),
			metadata: metadata,
			displayName: "Metadata Test",
			status: .issued
		)
		
		// When
		try await storage.saveDocument(document, batch: nil, allowOverwrite: true)
		let loaded = try await storage.loadDocument(id: "metadata-doc", status: .issued)
		
		// Then
		#expect(loaded?.metadata == metadata)
	}
	
	@Test("Document isDeferred property works correctly")
	func testDocumentIsDeferredProperty() async throws {
		// Given
		let deferredDoc = WalletStorage.Document(
			id: "deferred-check",
			docType: "org.iso.18013.5.1.mDL",
			docDataFormat: .cbor,
			data: "Data".data(using: .utf8)!,
			docKeyInfo: nil,
			createdAt: Date(),
			metadata: nil,
			displayName: "Deferred",
			status: .deferred
		)
		
		let issuedDoc = WalletStorage.Document(
			id: "issued-check",
			docType: "org.iso.18013.5.1.mDL",
			docDataFormat: .cbor,
			data: "Data".data(using: .utf8)!,
			docKeyInfo: nil,
			createdAt: Date(),
			metadata: nil,
			displayName: "Issued",
			status: .issued
		)
		
		// Then
		#expect(deferredDoc.isDeferred == true)
		#expect(issuedDoc.isDeferred == false)
	}
}

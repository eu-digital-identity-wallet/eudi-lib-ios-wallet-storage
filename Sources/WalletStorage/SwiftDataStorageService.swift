/*
 Copyright (c) 2026 European Commission
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import Foundation
import MdocDataModel18013
import SwiftData

@Model
public final class SwiftDataStoredDocument {
	@Attribute(.unique) var storageKey: String
	var documentId: String
	var credentialId: String
	var dataType: String
	var status: String
	var docType: String
	var docDataFormat: String
	var data: Data
	var docKeyInfo: Data?
	var createdAt: Date
	var modifiedAt: Date?
	var metadata: Data?
	
	init(
		storageKey: String,
		documentId: String,
		credentialId: String,
		dataType: SavedKeyChainDataType,
		status: DocumentStatus,
		document: Document
	) {
		self.storageKey = storageKey
		self.documentId = documentId
		self.credentialId = credentialId
		self.dataType = dataType.rawValue
		self.status = status.rawValue
		self.docType = document.docType
		self.docDataFormat = document.docDataFormat.rawValue
		self.data = document.data
		self.docKeyInfo = document.docKeyInfo
		self.createdAt = document.createdAt
		self.modifiedAt = document.modifiedAt
		self.metadata = document.metadata
	}
	
	func update(with document: Document) {
		docType = document.docType
		docDataFormat = document.docDataFormat.rawValue
		data = document.data
		docKeyInfo = document.docKeyInfo
		modifiedAt = Date()
		metadata = document.metadata
	}
	
	func makeDocument() -> Document {
		Document(
			id: documentId,
			docType: docType,
			docDataFormat: DocDataFormat(rawValue: docDataFormat) ?? .cbor,
			data: data,
			docKeyInfo: docKeyInfo,
			createdAt: createdAt,
			modifiedAt: modifiedAt,
			metadata: metadata,
			displayName: DocMetadata(from: metadata)?.getDisplayName(nil),
			status: DocumentStatus(rawValue: status) ?? .issued
		)
	}
}

/// Implements document storage using Apple's SwiftData framework.
public actor SwiftDataStorageService: DataStorageService {
	private let container: ModelContainer
	
	public init(modelContainer: ModelContainer) {
		self.container = modelContainer
	}
	
	public init(isStoredInMemoryOnly: Bool = false) throws {
		let schema = Schema([SwiftDataStoredDocument.self])
		let configuration = ModelConfiguration(
			schema: schema,
			isStoredInMemoryOnly: isStoredInMemoryOnly
		)
		self.container = try ModelContainer(
			for: schema,
			configurations: [configuration]
		)
	}
	
	public func loadDocument(id: String, status: DocumentStatus) async throws -> Document? {
		try await loadDocumentHelper(id: id, status: status)
	}
	
	public func loadDocumentMetadata(id: String, status: DocumentStatus) async throws -> DocMetadata? {
		let placeholderDocument = try await loadDocumentHelper(
			id: id,
			status: status,
			needIndexToUse: false
		)
		guard let placeholderDocument else { return nil }
		return DocMetadata(from: placeholderDocument.metadata)
	}
	
	public func loadDocuments(status: DocumentStatus) async throws -> [Document]? {
		logger.info("Load documents with status: \(status)")
		let context = ModelContext(container)
		let documents = try loadDocuments(
			id: nil,
			index: nil,
			status: status,
			context: context
		)
		return documents?.isEmpty == false ? documents : nil
	}
	
	public func saveDocument(_ document: Document, batch: [Document]?, allowOverwrite: Bool) async throws {
		logger.info("Save document for status: \(document.status), id: \(document.id), docType: \(document.docType)")
		let context = ModelContext(container)
		try upsert(
			document,
			documentId: document.id,
			credentialId: document.id,
			dataType: .docPresent,
			status: document.status,
			allowOverwrite: allowOverwrite,
			context: context
		)
		if let batch {
			for (index, doc) in batch.enumerated() {
				try upsert(
					doc,
					documentId: document.id,
					credentialId: "\(document.id)_\(index)",
					dataType: .doc,
					status: document.status,
					allowOverwrite: allowOverwrite,
					context: context
				)
			}
		}
		try context.save()
	}
	
	public func deleteDocument(id: String, status: DocumentStatus) async throws {
		logger.info("Delete document with status: \(status), id: \(id)")
		let context = ModelContext(container)
		let doc = try await loadDocumentHelper(
			id: id,
			status: status,
			needIndexToUse: false,
			context: context
		)
		let docKeyInfo = DocKeyInfo(from: doc?.docKeyInfo)
		try await deleteDocumentHelper(
			id: id,
			dki: docKeyInfo,
			status: status,
			context: context
		)
	}
	
	public func deleteDocuments(status: DocumentStatus) async throws {
		logger.info("Delete documents with status: \(status)")
		let context = ModelContext(container)
		let docs = try loadDocuments(
			id: nil,
			index: nil,
			status: status,
			context: context
		) ?? []
		for doc in docs {
			let docKeyInfo = DocKeyInfo(from: doc.docKeyInfo)
			try await deleteDocumentHelper(
				id: doc.id,
				dki: docKeyInfo,
				status: status,
				context: context
			)
		}
	}
	
	public func deleteDocumentCredential(id: String, index: Int) async throws {
		let context = ModelContext(container)
		try deleteDocumentData(
			id: "\(id)_\(index)",
			status: .issued,
			dataType: .doc,
			context: context
		)
		try context.save()
	}
	
	func loadDocumentHelper(
		id: String,
		status: DocumentStatus,
		needIndexToUse: Bool = true,
		context: ModelContext? = nil
	) async throws -> Document? {
		logger.info("Load document with status: \(status), id: \(id)")
		let context = context ?? ModelContext(container)
		let placeholderDocuments = try loadDocuments(
			id: id,
			index: nil,
			status: status,
			context: context
		)
		guard let placeholderDocument = placeholderDocuments?.first else { return nil }
		if !needIndexToUse { return placeholderDocument }
		guard let docKeyInfo = DocKeyInfo(from: placeholderDocument.docKeyInfo) else { return placeholderDocument }
		let secureArea = SecureAreaRegistry.shared.get(name: docKeyInfo.secureAreaName)
		let keyBatchInfo = try await secureArea.getKeyBatchInfo(id: id)
		let isUsedOneTimeCredential = keyBatchInfo.credentialPolicy == .oneTimeUse && keyBatchInfo.usedCounts[0] > 0
		guard keyBatchInfo.batchSize > 1 else { return isUsedOneTimeCredential ? nil : placeholderDocument }
		guard let indexToUse = keyBatchInfo.findIndexToUse() else { return nil }
		var doc = try loadDocuments(
			id: id,
			index: indexToUse,
			status: status,
			context: context
		)?.first
		doc?.keyIndex = indexToUse
		doc?.docKeyInfo = placeholderDocument.docKeyInfo
		doc?.metadata = placeholderDocument.metadata
		doc?.displayName = placeholderDocument.displayName
		return doc
	}
	
	func loadDocuments(
		id: String?,
		index: Int?,
		status: DocumentStatus,
		context: ModelContext
	) throws -> [Document]? {
		let credentialId: String? = if let id, let index {
			"\(id)_\(index)"
		} else if index == nil {
			id
		} else {
			nil
		}
		let dataType: SavedKeyChainDataType = if id != nil && index != nil { .doc } else { .docPresent }
		let records = try loadRecords(
			credentialId: credentialId,
			status: status,
			dataType: dataType,
			context: context
		)
		return records.map { $0.makeDocument() }
	}
	
	func deleteDocumentHelper(
		id: String,
		dki: DocKeyInfo?,
		status: DocumentStatus,
		context: ModelContext
	) async throws {
		try deleteDocumentData(
			id: id,
			status: status,
			dataType: .docPresent,
			context: context
		)
		guard let dki else {
			logger.info("Could not find key info for id: \(id)")
			try context.save()
			return
		}
		let secureArea = SecureAreaRegistry.shared.get(name: dki.secureAreaName)
		let keyBatchInfo = try await secureArea.getKeyBatchInfo(id: id)
		let isOneTimeUsePolicy = keyBatchInfo.credentialPolicy == .oneTimeUse
		guard status == .issued else {
			try context.save()
			return
		}
		for index in 0..<keyBatchInfo.usedCounts.count {
			let shouldSkipUsedCredential = isOneTimeUsePolicy && keyBatchInfo.usedCounts[index] > 0
			if shouldSkipUsedCredential { continue }
			try deleteDocumentData(
				id: "\(id)_\(index)",
				status: status,
				dataType: .doc,
				context: context
			)
		}
		if keyBatchInfo.credentialPolicy == .rotateUse {
			try await secureArea.deleteKeyBatch(id: id, startIndex: 0, batchSize: dki.batchSize)
		} else {
			for index in 0..<keyBatchInfo.usedCounts.count {
				let shouldSkipUsedCredential = isOneTimeUsePolicy && keyBatchInfo.usedCounts[index] > 0
				if shouldSkipUsedCredential { continue }
				try await secureArea.deleteKeyBatch(id: id, startIndex: index, batchSize: 1)
			}
		}
		try await secureArea.deleteKeyInfo(id: id)
		try context.save()
	}
	
	private func upsert(
		_ document: Document,
		documentId: String,
		credentialId: String,
		dataType: SavedKeyChainDataType,
		status: DocumentStatus,
		allowOverwrite: Bool,
		context: ModelContext
	) throws {
		let storageKey = Self.storageKey(
			credentialId: credentialId,
			status: status,
			dataType: dataType
		)
		if let record = try record(storageKey: storageKey, context: context) {
			guard allowOverwrite else {
				throw StorageError(description: "Document already exists")
			}
			record.update(with: document)
		} else {
			context.insert(
				SwiftDataStoredDocument(
					storageKey: storageKey,
					documentId: documentId,
					credentialId: credentialId,
					dataType: dataType,
					status: status,
					document: document
				)
			)
		}
	}
	
	private func deleteDocumentData(
		id: String,
		status: DocumentStatus,
		dataType: SavedKeyChainDataType,
		context: ModelContext
	) throws {
		let storageKey = Self.storageKey(
			credentialId: id,
			status: status,
			dataType: dataType
		)
		guard let record = try record(storageKey: storageKey, context: context) else {
			throw StorageError(description: "Document not found")
		}
		context.delete(record)
	}
	
	private func loadRecords(
		credentialId: String?,
		status: DocumentStatus,
		dataType: SavedKeyChainDataType,
		context: ModelContext
	) throws -> [SwiftDataStoredDocument] {
		var descriptor: FetchDescriptor<SwiftDataStoredDocument>
		if let credentialId {
			let storageKey = Self.storageKey(
				credentialId: credentialId,
				status: status,
				dataType: dataType
			)
			descriptor = FetchDescriptor(
				predicate: #Predicate { $0.storageKey == storageKey },
				sortBy: [SortDescriptor(\.createdAt)]
			)
		} else {
			let statusValue = status.rawValue
			let dataTypeValue = dataType.rawValue
			descriptor = FetchDescriptor(
				predicate: #Predicate {
					$0.status == statusValue && $0.dataType == dataTypeValue
				},
				sortBy: [SortDescriptor(\.createdAt)]
			)
		}
		return try context.fetch(descriptor)
	}
	
	private func record(
		storageKey: String,
		context: ModelContext
	) throws -> SwiftDataStoredDocument? {
		var descriptor = FetchDescriptor<SwiftDataStoredDocument>(
			predicate: #Predicate { $0.storageKey == storageKey }
		)
		descriptor.fetchLimit = 1
		return try context.fetch(descriptor).first
	}
	
	private nonisolated static func storageKey(
		credentialId: String,
		status: DocumentStatus,
		dataType: SavedKeyChainDataType
	) -> String {
		[dataType.rawValue, status.rawValue, credentialId].joined(separator: ":")
	}
}

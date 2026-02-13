/*
Copyright (c) 2023 European Commission

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
@testable import WalletStorage

/// In-memory implementation of DataStorageService for testing purposes
public actor InMemoryDataStorageService: DataStorageService {
	
	private var documents: [String: [WalletStorage.Document]] = [:]
	
	public init() {}
	
	/// Load a document with the specified id and status
	public func loadDocument(id: String, status: DocumentStatus) async throws -> WalletStorage.Document? {
		let key = makeKey(id: id, status: status)
		guard let docs = documents[key], !docs.isEmpty else { return nil }
		
		// Get placeholder document
		let doc0 = docs[0]
		guard let dki = DocKeyInfo(from: doc0.docKeyInfo) else { return doc0 }
		
		let secureArea = SecureAreaRegistry.shared.get(name: dki.secureAreaName)
		let keyBatchInfo = try await secureArea.getKeyBatchInfo(id: id)
		
		guard keyBatchInfo.batchSize > 1 else {
			return keyBatchInfo.credentialPolicy == .oneTimeUse && keyBatchInfo.usedCounts[0] > 0 ? nil : doc0
		}
		
		guard let indexToUse = keyBatchInfo.findIndexToUse() else { return nil }
		
		// Find document at the specified index
		let batchKey = makeKey(id: "\(id)_\(indexToUse)", status: status)
		guard let batchDocs = documents[batchKey], let doc = batchDocs.first else { return nil }
		
		var mutableDoc = doc
		mutableDoc.keyIndex = indexToUse
		mutableDoc.docKeyInfo = doc0.docKeyInfo
		return mutableDoc
	}
	
	/// Load placeholder documents for display
	public func loadDocuments(status: DocumentStatus) async throws -> [WalletStorage.Document]? {
		let filteredDocs = documents.filter { key, _ in
			key.hasSuffix(":\(status.rawValue)")
		}.flatMap { $0.value }
		
		return filteredDocs.isEmpty ? nil : filteredDocs
	}
	
	/// Save a document and optionally a batch of documents
	public func saveDocument(_ document: WalletStorage.Document, batch: [WalletStorage.Document]?, allowOverwrite: Bool) async throws {
		let key = makeKey(id: document.id, status: document.status)
		
		if !allowOverwrite && documents[key] != nil {
			throw StorageError(description: "Document already exists", code: -1)
		}
		
		// Save placeholder document
		documents[key] = [document]
		
		// Save batch if provided
		if let batch = batch {
			for (index, doc) in batch.enumerated() {
				let batchKey = makeKey(id: "\(document.id)_\(index)", status: document.status)
				documents[batchKey] = [doc]
			}
		}
	}
	
	/// Delete a document and the batch of credentials with the specified id and status
	public func deleteDocument(id: String, status: DocumentStatus) async throws {
		let key = makeKey(id: id, status: status)
		guard let doc = documents[key]?.first else {
			throw StorageError(description: "Document not found", code: -2)
		}
		
		let dki = DocKeyInfo(from: doc.docKeyInfo)
		
		// Delete placeholder document
		documents.removeValue(forKey: key)
		
		// Delete batch documents if they exist
		if let dki = dki, status == .issued {
			for index in 0..<dki.batchSize {
				let batchKey = makeKey(id: "\(id)_\(index)", status: status)
				documents.removeValue(forKey: batchKey)
			}
			
			// Delete keys from secure area
			let secureArea = SecureAreaRegistry.shared.get(name: dki.secureAreaName)
			try await secureArea.deleteKeyBatch(id: id, startIndex: 0, batchSize: dki.batchSize)
			try await secureArea.deleteKeyInfo(id: id)
		}
	}
	
	/// Delete all documents with the specified status
	public func deleteDocuments(status: DocumentStatus) async throws {
		let keysToDelete = documents.keys.filter { $0.hasSuffix(":\(status.rawValue)") }
		
		for key in keysToDelete {
			if let doc = documents[key]?.first {
				let id = doc.id
				documents.removeValue(forKey: key)
				
				let dki = DocKeyInfo(from: doc.docKeyInfo)
				if let dki = dki, status == .issued {
					for index in 0..<dki.batchSize {
						let batchKey = makeKey(id: "\(id)_\(index)", status: status)
						documents.removeValue(forKey: batchKey)
					}
					
					// Delete keys from secure area
					let secureArea = SecureAreaRegistry.shared.get(name: dki.secureAreaName)
					try? await secureArea.deleteKeyBatch(id: id, startIndex: 0, batchSize: dki.batchSize)
					try? await secureArea.deleteKeyInfo(id: id)
				}
			}
		}
	}
	
	/// Delete document credential at a specified index
	public func deleteDocumentCredential(id: String, index: Int) async throws {
		let batchKey = makeKey(id: "\(id)_\(index)", status: .issued)
		if documents[batchKey] == nil {
			throw StorageError(description: "Document credential not found", code: -2)
		}
		documents.removeValue(forKey: batchKey)
	}
	
	// MARK: - Helper Methods
	
	private func makeKey(id: String, status: DocumentStatus) -> String {
		return "\(id):\(status.rawValue)"
	}
}

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
/// Implements key-chain storage
/// Documents are saved as a pair of generic password items (document data and private key)
/// For implementation details, see [Apple documentation]
/// (https://developer.apple.com/documentation/security/ksecclassgenericpassword)
public actor KeyChainStorageService: DataStorageService  {

	public init(serviceName: String, accessGroup: String? = nil) {
		self.serviceName = serviceName
		self.accessGroup = accessGroup
	}
	
	public let serviceName: String
	public let accessGroup: String?
	var documentToSave: Document?
	
	/// Gets the secret document by id passed in parameter
	/// - Parameter id: Document identifier
	/// - Returns: The document if exists
	public func loadDocument(id: String, status: DocumentStatus) async throws -> Document? {
		return try await loadDocumentHelper(id: id, status: status)
	}
    
    public func loadDocumentMetadata(id: String) async throws -> MdocDataModel18013.DocMetadata? {
        let placeholderDocument = try await loadDocumentHelper(
            id: id,
            status: .issued,
            needIndexToUse: false
        )
        guard let placeholderDocument else { return nil }
        let docMetadata = DocMetadata(from: placeholderDocument.metadata)
        return docMetadata
    }
	
	public func loadDocumentHelper(
		id: String,
		status: DocumentStatus,
		needIndexToUse: Bool = true
	) async throws -> Document? {
		logger.info("Load document with status: \(status), id: \(id)")
		// get placeholder document to find index in batch
		let placeholderDocuments = try loadDocuments(id: id, index: nil, status: status)
		guard let placeholderDocument = placeholderDocuments?.first else { return nil }
		if !needIndexToUse { return placeholderDocument }
		guard let docKeyInfo = DocKeyInfo(from: placeholderDocument.docKeyInfo) else { return nil }
		let secureArea = SecureAreaRegistry.shared.get(name: docKeyInfo.secureAreaName)
		let keyBatchInfo = try await secureArea.getKeyBatchInfo(id: id)
		let isUsedOneTimeCredential = keyBatchInfo.credentialPolicy == .oneTimeUse && keyBatchInfo.usedCounts[0] > 0
		guard keyBatchInfo.batchSize > 1 else { return isUsedOneTimeCredential ? nil : placeholderDocument }
		guard let indexToUse = keyBatchInfo.findIndexToUse() else { return nil }
		var doc = try loadDocuments(id: id, index: indexToUse, status: status)?.first
		doc?.keyIndex = indexToUse
		doc?.docKeyInfo = placeholderDocument.docKeyInfo
        doc?.metadata = placeholderDocument.metadata
		return doc
	}
	
	public func loadDocuments(status: DocumentStatus) throws -> [Document]? {
		logger.info("Load documents with status: \(status)")
		return try loadDocuments(id: nil, index: nil, status: status)
	}

	/// Gets all documents
	/// - Parameters:
	/// - Returns: The documents stored in keychain under the serviceName
	func loadDocuments(id: String?, index: Int?, status: DocumentStatus) throws -> [Document]? {
		// If id is nil, load all placeholder documents for display (not presentation).
		// If index is nil, load placeholder document for a specific id.
		let idToLoad: String? = if let id, let index {
			"\(id)_\(index)"
		} else if index == nil {
			id
		} else {
			nil
		}
		let loadType: SavedKeyChainDataType = if id != nil && index != nil { .doc } else { .docPresent }
		guard let dicts = try Self.loadData(
			serviceName: serviceName,
			accessGroup: accessGroup,
			id: idToLoad,
			status: status,
			dataToLoadType: loadType
		) else { return nil }
		let documents = dicts.compactMap { d in Self.makeDocument(dict: d, status: status) }
		return documents
	}
	
	nonisolated static func loadData(
		serviceName: String,
		accessGroup: String?,
		id: String?,
		status: DocumentStatus,
		dataToLoadType: SavedKeyChainDataType
	) throws -> [[String: Any]]? {
		let query = Self.makeQuery(
			serviceName: serviceName,
			accessGroup: accessGroup,
			id: id,
			bForSave: false,
			status: status,
			dataType: dataToLoadType
		)
		var result: CFTypeRef?
		let status = SecItemCopyMatching(query as CFDictionary, &result)
		if status == errSecItemNotFound { return nil }
		let statusMessage = SecCopyErrorMessageString(status, nil) as? String
		guard status == errSecSuccess else {
			logger.error("Error code: \(Int(status)), description: \(statusMessage ?? "")")
			throw StorageError(description: statusMessage ?? "", code: Int(status))
		}
		if let resultDictionaries = result as? [[String: Any]] { return resultDictionaries }
		else if let resultDictionary = result as? [String: Any] { return [resultDictionary] }
		else { return nil }
	}
	
	/// Save the secret to keychain
	/// Note: the value passed in will be zeroed out after the secret is saved
	/// - Parameters:
	///   - document: The document to save
	public func saveDocument(_ document: Document, batch: [Document]?, allowOverwrite: Bool = true) throws {
		documentToSave = document
		// kSecAttrAccount is used to store the secret Id  (we save the document ID)
		// kSecAttrService is a key whose value is a string indicating the item's service.
		let documentStatus = document.status
		let documentId = document.id
		let documentType = document.docType
		let saveLogMessage = "Save document for status: \(documentStatus), id: \(documentId), " +
			"docType: \(documentType)"
		logger.info("\(saveLogMessage)")
		let id = document.id
		try Self.saveDocumentData(
			serviceName: serviceName,
			accessGroup: accessGroup,
			id: id,
			status: document.status,
			dataType: .docPresent,
			setDictValues: setDictValues,
			allowOverwrite: allowOverwrite
		)
		if let batch {
			for (index, doc) in batch.enumerated() {
				documentToSave = doc
				let batchDocumentId = "\(id)_\(index)"
				try Self.saveDocumentData(
					serviceName: serviceName,
					accessGroup: accessGroup,
					id: batchDocumentId,
					status: document.status,
					dataType: .doc,
					setDictValues: setDictValues,
					allowOverwrite: allowOverwrite
				)
			}
		}
	}
	
	func setDictValues(_ d: inout [String: Any]) {
		guard let documentToSave else { return }
		d[kSecValueData as String] = documentToSave.data
		// use this attribute to differentiate between document and key data
		d[kSecAttrLabel as String] = documentToSave.docType
		if let md = documentToSave.metadata { d[kSecAttrDescription as String] = md.base64EncodedString() }
		if let dki = documentToSave.docKeyInfo { d[kSecAttrComment as String] = dki.base64EncodedString() }
		d[kSecAttrType as String] = documentToSave.docDataFormat.rawValue
		d[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
	}
	
	/// Make a query for a an item in keychain
	/// - Parameters:
	///   - id: id
	///   - bAll: request all matching items
	/// - Returns: The dictionary query
	nonisolated static func makeQuery(
		serviceName: String,
		accessGroup: String?,
		id: String?,
		bForSave: Bool,
		status: DocumentStatus,
		dataType: SavedKeyChainDataType
	) -> [String: Any] {
		let comps = [serviceName, dataType.rawValue, status.rawValue ]
		let queryValue = comps.joined(separator: ":")
		var query: [String: Any] = [
			kSecClass: kSecClassGenericPassword,
			kSecAttrService: queryValue,
			kSecUseDataProtectionKeychain: true
		] as [String: Any]
		if !bForSave {
			query[kSecReturnAttributes as String] = true
			query[kSecReturnData as String] = true
		}
		if let id {
			query[kSecAttrAccount as String] = id
		} else {
			query[kSecMatchLimit as String] = kSecMatchLimitAll
		}
        logger.info("Keychain queryValue: \(queryValue) id:\(id ?? "") for save:\(bForSave)")
		if let accessGroup, !accessGroup.isEmpty { query[kSecAttrAccessGroup as String] = accessGroup }
		return query
	}
	
	public nonisolated static func saveDocumentData(
		serviceName: String,
		accessGroup: String?,
		id: String,
		status: DocumentStatus,
		dataType: SavedKeyChainDataType,
		setDictValues: (inout [String: Any]) -> Void,
		allowOverwrite: Bool
	) throws {
		var query: [String: Any] = Self.makeQuery(
			serviceName: serviceName,
			accessGroup: accessGroup,
			id: id,
			bForSave: true,
			status: status,
			dataType: dataType
		)
		setDictValues(&query)
		var status = SecItemAdd(query as CFDictionary, nil)
		if allowOverwrite && status == errSecDuplicateItem {
			var updated: [String: Any] = [:]
			setDictValues(&updated)
			status = SecItemUpdate(query as CFDictionary, updated as CFDictionary)
		}
		let statusMessage = SecCopyErrorMessageString(status, nil) as? String
		guard status == errSecSuccess else {
			logger.error("Error code: \(Int(status)), description: \(statusMessage ?? "")")
			throw StorageError(description: statusMessage ?? "", code: Int(status))
		}
	}
	
	/// Delete the credemtial and key batch from keychain
	/// Note: the value passed in will be zeroed out after the secret is deleted
	/// - Parameters:
	///   - id: The Id of the secret
	public func deleteDocument(id: String, status: DocumentStatus) async throws {
		logger.info("Delete document with status: \(status), id: \(id)")
		let doc = try await loadDocumentHelper(id: id, status: status, needIndexToUse: false)
		let docKeyInfo = DocKeyInfo(from: doc?.docKeyInfo)
		try await deleteDocumentHelper(id: id, dki: docKeyInfo, status: status)
	}
			
	func deleteDocumentHelper(id: String, dki: DocKeyInfo?, status: DocumentStatus) async throws {
		try Self.deleteDocumentData(
			serviceName: serviceName,
			accessGroup: accessGroup,
			id: id,
			docStatus: status,
			dataType: .docPresent
		)
		guard let dki else { logger.info("Could not find key info for id: \(id)"); return }
		let secureArea = SecureAreaRegistry.shared.get(name: dki.secureAreaName)
		let keyBatchInfo = try await secureArea.getKeyBatchInfo(id: id)
		let isOneTimeUsePolicy = keyBatchInfo.credentialPolicy == .oneTimeUse
		guard status == .issued else { return }
		for index in 0..<keyBatchInfo.usedCounts.count {
			let shouldSkipUsedCredential = isOneTimeUsePolicy && keyBatchInfo.usedCounts[index] > 0
			if shouldSkipUsedCredential { continue }
			let credentialId = "\(id)_\(index)"
			try Self.deleteDocumentData(
				serviceName: serviceName,
				accessGroup: accessGroup,
				id: credentialId,
				docStatus: status,
				dataType: .doc
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
	}
	
	public func deleteDocumentCredential(id: String, index: Int) async throws {
		let credentialId = "\(id)_\(index)"
		try Self.deleteDocumentData(
			serviceName: serviceName,
			accessGroup: accessGroup,
			id: credentialId,
			docStatus: .issued,
			dataType: .doc
		)
	}
	
	public nonisolated static func deleteDocumentData(
		serviceName: String,
		accessGroup: String?,
		id: String,
		docStatus: DocumentStatus,
		dataType: SavedKeyChainDataType
	) throws {
		var query: [String: Any] = makeQuery(
			serviceName: serviceName,
			accessGroup: accessGroup,
			id: id,
			bForSave: false,
			status: docStatus,
			dataType: dataType
		)
		query.removeValue(forKey: kSecMatchLimit as String) 
		let status = SecItemDelete(query as CFDictionary)
		let statusMessage = SecCopyErrorMessageString(status, nil) as? String
		if status != errSecSuccess {
			logger.error("Error code: \(Int(status)), description: \(statusMessage ?? "")")
			throw StorageError(description: statusMessage ?? "", code: Int(status))
		}
	}
	
	/// Delete all documents from keychain
	/// - Parameters:
	///   - id: The Id of the secret
	public func deleteDocuments(status: DocumentStatus) async throws {
		logger.info("Delete documents with status: \(status)")
		let docs = try loadDocuments(id: nil, index: nil, status: status) ?? []
		for doc in docs {
			let docKeyInfo = DocKeyInfo(from: doc.docKeyInfo)
			try await deleteDocumentHelper(id: doc.id, dki: docKeyInfo, status: status)
		}
	}
	
	/// Make a document from a keychain item
	/// - Parameter dict: keychain item returned as dictionary
	/// - Returns: the document
	static func makeDocument(dict: [String: Any], status: DocumentStatus) -> Document? {
		guard var data = dict[kSecValueData as String] as? Data else { return nil }
		defer { let c = data.count; data.withUnsafeMutableBytes { memset_s($0.baseAddress, c, 0, c); return } }
		// load metadata from description column
		let metadataBase64 = dict[kSecAttrDescription as String] as? String
		let metadataData: Data? = if let metadataBase64 { Data(base64Encoded: metadataBase64) } else { nil }
		// load key usage from comment column
		let keyInfoBase64 = dict[kSecAttrComment as String] as? String
		let keyInfoData: Data? = if let keyInfoBase64 { Data(base64Encoded: keyInfoBase64) } else { nil }
		let accountId = dict[kSecAttrAccount as String] as! String
		let documentType = dict[kSecAttrLabel as String] as! String
		let docDataFormatRawValue = dict[kSecAttrType as String] as? String ?? DocDataFormat.cbor.rawValue
		let documentDataFormat = DocDataFormat(rawValue: docDataFormatRawValue) ?? DocDataFormat.cbor
		let creationDate = dict[kSecAttrCreationDate as String] as! Date
		let modificationDate = dict[kSecAttrModificationDate as String] as? Date
		return Document(
			id: accountId,
			docType: documentType,
			docDataFormat: documentDataFormat,
			data: data,
			docKeyInfo: keyInfoData,
			createdAt: creationDate,
			modifiedAt: modificationDate,
			metadata: metadataData,
			displayName: nil,
			status: status
		)
	}
}

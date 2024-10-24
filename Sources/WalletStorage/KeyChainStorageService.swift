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
/// For implementation details see [Apple documentation](https://developer.apple.com/documentation/security/ksecclassgenericpassword)
public actor KeyChainStorageService: DataStorageService, SecureKeyStorage {

	public init(serviceName: String, accessGroup: String? = nil) {
		self.serviceName = serviceName
		self.accessGroup = accessGroup
	}
	
	public var serviceName: String
	public var accessGroup: String?
	
	public func initialize(_ serviceName: String, _ accessGroup: String?) {
		self.serviceName = serviceName
		self.accessGroup = accessGroup
	}
	/// Gets the secret document by id passed in parameter
	/// - Parameter id: Document identifier
	/// - Returns: The document if exists
	public func loadDocument(id: String, status: DocumentStatus) throws -> Document? {
		logger.info("Load document with status: \(status), id: \(id)")
		return try loadDocuments(id: id, status: status)?.first
	}
	public func loadDocuments(status: DocumentStatus) throws -> [Document]? {
		logger.info("Load documents with status: \(status)")
		return try loadDocuments(id: nil, status: status)
	}
	// use is-negative to denote type of data
	static func isDocumentDataRow(_ d: [String: Any]) -> Bool { if let b = d[kSecAttrIsNegative as String] as? Bool { !b } else { true } }
	static func isPrivateKeyRow(_ d: [String: Any]) -> Bool { if let b = d[kSecAttrIsNegative as String] as? Bool { b } else { false } }

	/// Gets all documents
	/// - Parameters:
	/// - Returns: The documents stored in keychain under the serviceName
	func loadDocuments(id: String?, status: DocumentStatus) throws -> [Document]? {
		guard var dicts = try loadDocumentsData(id: id, docStatus: status) else { return nil }
		let documents = dicts.compactMap { d in Self.makeDocument(dict: d, status: status) }
		return documents
	}
	
	func loadDocumentsData(id: String?, docStatus: DocumentStatus, dataToLoadType: SavedKeyChainDataType = .doc) throws -> [[String: Any]]? {
		let query = makeQuery(id: id, bForSave: false, status: docStatus, dataType: dataToLoadType)
		var result: CFTypeRef?
		let status = SecItemCopyMatching(query as CFDictionary, &result)
		if status == errSecItemNotFound { return nil }
		let statusMessage = SecCopyErrorMessageString(status, nil) as? String
		guard status == errSecSuccess else {
			logger.error("Error code: \(Int(status)), description: \(statusMessage ?? "")")
			throw StorageError(description: statusMessage ?? "", code: Int(status))
		}
		var res = result as! [[String: Any]]
		return res
	}
	
	/// Save the secret to keychain
	/// Note: the value passed in will be zeroed out after the secret is saved
	/// - Parameters:
	///   - document: The document to save
	public func saveDocument(_ document: Document, allowOverwrite: Bool = true) throws {
		try saveDocumentData(document, dataType: document.docDataType.rawValue, allowOverwrite: allowOverwrite)
	}
	
	/// Make a query for a an item in keychain
	/// - Parameters:
	///   - id: id
	///   - bAll: request all matching items
	/// - Returns: The dictionary query
	func makeQuery(id: String?, bForSave: Bool, status: DocumentStatus, dataType: SavedKeyChainDataType) -> [String: Any] {
		let comps = [serviceName, dataType.rawValue, status.rawValue ]
		let queryValue = comps.joined(separator: ":")
		var query: [String: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: queryValue, kSecUseDataProtectionKeychain: true] as [String: Any]
		if !bForSave {
			query[kSecReturnAttributes as String] = true
		}
		if let id { query[kSecAttrAccount as String] = id } else { query[kSecMatchLimit as String] = kSecMatchLimitAll }
		if let accessGroup, !accessGroup.isEmpty { query[kSecAttrAccessGroup as String] = accessGroup }
		return query
	}
	
	static func getIsNegativeValueToUse(_ dataToSaveType: SavedKeyChainDataType) -> Bool { switch dataToSaveType { case .key: true; default: false } }
	
	public func saveDocumentData(_ document: Document, dataType: String, allowOverwrite: Bool = true) throws {
		// kSecAttrAccount is used to store the secret Id  (we save the document ID)
		// kSecAttrService is a key whose value is a string indicating the item's service.
		logger.info("Save document for status: \(document.status), id: \(document.id), docType: \(document.docType), displayName: \(document.displayName ?? "")")
		guard dataType.count == 4 else { throw StorageError(description: "Invalid type") }
		var query: [String: Any] = makeQuery(id: document.id, bForSave: true, status: document.status, dataType: .doc)
		func setDictValues(d: inout [String: Any]) {
			d[kSecValueData as String] = document.data
			// use this attribute to differentiate between document and key data
			d[kSecAttrIsNegative as String] = Self.getIsNegativeValueToUse(.doc)
			d[kSecAttrLabel as String] = document.docType
			if let dn = document.displayName { d[kSecAttrDescription as String] = dn }
			if let san = document.secureAreaName { d[kSecAttrComment as String] = san }
			d[kSecAttrType as String] = dataType
		}
		setDictValues(d: &query)
		var status = SecItemAdd(query as CFDictionary, nil)
		if allowOverwrite && status == errSecDuplicateItem {
			var updated: [String: Any] = [:]
			setDictValues(d: &updated)
			status = SecItemUpdate(query as CFDictionary, updated as CFDictionary)
		}
		let statusMessage = SecCopyErrorMessageString(status, nil) as? String
		guard status == errSecSuccess else {
			logger.error("Error code: \(Int(status)), description: \(statusMessage ?? "")")
			throw StorageError(description: statusMessage ?? "", code: Int(status))
		}
	}
	
	public func readKeyInfo(id: String) throws -> [String : Data] {
	[:]
	}
	
	public func readKeyData(id: String) throws -> [String : Data] {
	[:]
	}
	// save key public info
	public func writeKeyInfo(id: String, dict: [String: Data]) throws {}
	// save key sensitive info
	public func writeKeyData(id: String, dict: [String: Data]) throws {}
	// delete key info and data
	public func deleteKey(id: String) throws {}
	/// Delete the secret from keychain
	/// Note: the value passed in will be zeroed out after the secret is deleted
	/// - Parameters:
	///   - id: The Id of the secret
	public func deleteDocument(id: String, status: DocumentStatus) throws {
		logger.info("Delete document with status: \(status), id: \(id)")
		try deleteDocumentData(id: id, docStatus: status)
	}
	
	public func deleteDocumentData(id: String?, docStatus: DocumentStatus, dataType: SavedKeyChainDataType = .doc) throws {
		let query: [String: Any] = makeQuery(id: id, bForSave: true, status: docStatus, dataType: dataType)
		let status = SecItemDelete(query as CFDictionary)
		let statusMessage = SecCopyErrorMessageString(status, nil) as? String
		if status == errSecItemNotFound, id == nil {
			let msg = statusMessage ?? "No items found"
			logger.warning("\(msg)")
		} else if status != errSecSuccess {
			logger.error("Error code: \(Int(status)), description: \(statusMessage ?? "")")
			throw StorageError(description: statusMessage ?? "", code: Int(status))
		}
		if dataType == .doc { try deleteDocumentData(id: id, docStatus: docStatus, dataType: .key) }
	}
	
	/// Delete all documents from keychain
	/// - Parameters:
	///   - id: The Id of the secret
	public func deleteDocuments(status: DocumentStatus) throws {
		logger.info("Delete documents with status: \(status)")
		try deleteDocumentData(id: nil, docStatus: status)
	}
	
	/// Make a document from a keychain item
	/// - Parameter dict: keychain item returned as dictionary
	/// - Returns: the document
	static func makeDocument(dict: [String: Any], status: DocumentStatus) -> Document {
		var data = dict[kSecValueData as String] as! Data
		defer { let c = data.count; data.withUnsafeMutableBytes { memset_s($0.baseAddress, c, 0, c); return } }
		return Document(id: dict[kSecAttrAccount as String] as! String, docType: dict[kSecAttrLabel as String] as? String ?? "", docDataType: DocDataType(rawValue: dict[kSecAttrType as String] as? String ?? DocDataType.cbor.rawValue) ?? DocDataType.cbor, data: data, secureAreaName: dict[kSecAttrComment as String] as? String, createdAt: (dict[kSecAttrCreationDate as String] as! Date), modifiedAt: dict[kSecAttrModificationDate as String] as? Date, displayName: dict[kSecAttrDescription as String] as? String, status: status)
	}
}

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
/// Implements key-chain storage
/// Documents are saved as a pair of generic password items (document data and private key)
/// For implementation details see [Apple documentation](https://developer.apple.com/documentation/security/ksecclassgenericpassword)
public class KeyChainStorageService: DataStorageService {
	
	public init(serviceName: String, accessGroup: String? = nil) {
		self.serviceName = serviceName
		self.accessGroup = accessGroup
	}
	
	public var serviceName: String
	public var accessGroup: String?
	
	/// Gets the secret document by id passed in parameter
	/// - Parameter id: Document identifier
	/// - Returns: The document if exists
	public func loadDocument(id: String, status: DocumentStatus) throws -> Document? {
		try loadDocuments(id: id, status: status)?.first
	}
	public func loadDocuments(status: DocumentStatus) throws -> [Document]? {
		try loadDocuments(id: nil, status: status)
	}
	// use is-negative to denote type of data
	static func isDocumentDataRow(_ d: [String: Any]) -> Bool { if let b = d[kSecAttrIsNegative as String] as? Bool { !b } else { true } }
	static func isPrivateKeyRow(_ d: [String: Any]) -> Bool { if let b = d[kSecAttrIsNegative as String] as? Bool { b } else { false } }

	/// Gets all documents
	/// - Parameters:
	/// - Returns: The documents stored in keychain under the serviceName
	func loadDocuments(id: String?, status: DocumentStatus) throws -> [Document]? {
		guard var dicts1 = try loadDocumentsData(id: id, docStatus: status) else { return nil }
		let dicts2 = dicts1.filter(Self.isPrivateKeyRow)
		dicts1 = dicts1.filter(Self.isDocumentDataRow)
		let documents = dicts1.compactMap { d1 in Self.makeDocument(dict1: d1, dict2: dicts2.first(where: { d2 in d1[kSecAttrAccount as String] as! String == d2[kSecAttrAccount as String] as! String}), status: status) }
		return documents
	}
	
	func loadDocumentsData(id: String?, docStatus: DocumentStatus, dataToLoadType: SavedKeyChainDataType = .doc, bCompatOldVersion: Bool = false) throws -> [[String: Any]]? {
		var query = makeQuery(id: id, bForSave: false, status: docStatus, dataType: dataToLoadType)
		if bCompatOldVersion { query[kSecAttrService as String] = if dataToLoadType == .doc { serviceName } else { serviceName + "_key" } } // to be removed in version 1
		var result: CFTypeRef?
		let status = SecItemCopyMatching(query as CFDictionary, &result)
		if status == errSecItemNotFound { return nil }
		let statusMessage = SecCopyErrorMessageString(status, nil) as? String
		guard status == errSecSuccess else {
			throw StorageError(description: statusMessage ?? "", code: Int(status))
		}
		var res = result as! [[String: Any]]
		if !bCompatOldVersion, dataToLoadType == .doc {
			if let dicts2 = try loadDocumentsData(id: id, docStatus: docStatus, dataToLoadType: .key, bCompatOldVersion: bCompatOldVersion) { res.append(contentsOf: dicts2) }
		}
		// following lines to be removed in version 1
		if !bCompatOldVersion, dataToLoadType == .doc { if let dicts1 = try loadDocumentsData(id: id, docStatus: docStatus, dataToLoadType: .doc, bCompatOldVersion: true) { res.append(contentsOf: dicts1) } }
		if !bCompatOldVersion, dataToLoadType == .key { if let dicts2 = try loadDocumentsData(id: id, docStatus: docStatus, dataToLoadType: .key, bCompatOldVersion: true) {dicts2.forEach { d in var d2 = d; d2[kSecAttrIsNegative as String] = true; res.append(d2) } } }
		return res
	}
	
	/// Save the secret to keychain
	/// Note: the value passed in will be zeroed out after the secret is saved
	/// - Parameters:
	///   - document: The document to save
	public func saveDocument(_ document: Document, allowOverwrite: Bool = true) throws {
		try saveDocumentData(document, dataToSaveType: .doc, dataType: document.docDataType.rawValue, allowOverwrite: allowOverwrite)
		if document.docDataType != .signupResponseJson {
			try saveDocumentData(document, dataToSaveType: .key, dataType: document.privateKeyType!.rawValue, allowOverwrite: allowOverwrite)
		}
	}
	
	/// Make a query for a an item in keychain
	/// - Parameters:
	///   - id: id
	///   - bAll: request all matching items
	/// - Returns: The dictionary query
	func makeQuery(id: String?, bForSave: Bool, status: DocumentStatus, dataType: SavedKeyChainDataType) -> [String: Any] {
		let comps = [serviceName, dataType.rawValue, status.rawValue ]
		let queryValue = comps.joined(separator: ":")
		var query: [String: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: queryValue] as [String: Any]
		if !bForSave {
			query[kSecReturnData as String] = true
			query[kSecReturnAttributes as String] = true
			query[kSecMatchLimit as String] = kSecMatchLimitAll
		}
		if let id { query[kSecAttrAccount as String] = id}
		if let accessGroup, !accessGroup.isEmpty { query[kSecAttrAccessGroup as String] = accessGroup }
		return query
	}
	
	static func getIsNegativeValueToUse(_ dataToSaveType: SavedKeyChainDataType) -> Bool { switch dataToSaveType { case .key: true; default: false } }
	
	public func saveDocumentData(_ document: Document, dataToSaveType: SavedKeyChainDataType, dataType: String, allowOverwrite: Bool = true) throws {
		// kSecAttrAccount is used to store the secret Id  (we save the document ID)
		// kSecAttrService is a key whose value is a string indicating the item's service.
		guard dataType.count == 4 else { throw StorageError(description: "Invalid type") }
		if dataToSaveType == .key && document.privateKey == nil { throw StorageError(description: "Private key not available") }
		var query: [String: Any] = makeQuery(id: document.id, bForSave: true, status: document.status, dataType: dataToSaveType)
		#if os(macOS)
		query[kSecUseDataProtectionKeychain as String] = true
	   #endif
		query[kSecValueData as String] = switch dataToSaveType { case .key: document.privateKey!; default: document.data }
		// use this attribute to differentiate between document and key data
		query[kSecAttrIsNegative as String] = Self.getIsNegativeValueToUse(dataToSaveType)
		query[kSecAttrLabel as String] = document.docType
		query[kSecAttrType as String] = dataType
		var status = SecItemAdd(query as CFDictionary, nil)
		if allowOverwrite && status == errSecDuplicateItem {
			let updated: [String: Any] = [kSecValueData: query[kSecValueData as String] as! Data, kSecAttrIsNegative: Self.getIsNegativeValueToUse(dataToSaveType), kSecAttrLabel: document.docType, kSecAttrType: dataType] as [String: Any]
			query = makeQuery(id: document.id, bForSave: true, status: document.status, dataType: dataToSaveType)
			status = SecItemUpdate(query as CFDictionary, updated as CFDictionary)
		}
		let statusMessage = SecCopyErrorMessageString(status, nil) as? String
		guard status == errSecSuccess else {
			throw StorageError(description: statusMessage ?? "", code: Int(status))
		}
	}
	
	/// Delete the secret from keychain
	/// Note: the value passed in will be zeroed out after the secret is deleted
	/// - Parameters:
	///   - id: The Id of the secret
	public func deleteDocument(id: String, status: DocumentStatus) throws {
		try deleteDocumentData(id: id, docStatus: status)
	}
	
	public func deleteDocumentData(id: String?, docStatus: DocumentStatus, dataType: SavedKeyChainDataType = .doc) throws {
		let query: [String: Any] = makeQuery(id: id, bForSave: true, status: docStatus, dataType: dataType)
		let status = SecItemDelete(query as CFDictionary)
		let statusMessage = SecCopyErrorMessageString(status, nil) as? String
		guard status == errSecSuccess else { throw StorageError(description: statusMessage ?? "", code: Int(status)) }
		if dataType == .doc { try deleteDocumentData(id: id, docStatus: docStatus, dataType: .key) }
	}
	
	/// Delete all documents from keychain
	/// - Parameters:
	///   - id: The Id of the secret
	public func deleteDocuments(status: DocumentStatus) throws {
		try deleteDocumentData(id: nil, docStatus: status)
	}
	
	/// Make a document from a keychain item
	/// - Parameter dict: keychain item returned as dictionary
	/// - Returns: the document
	static func makeDocument(dict1: [String: Any], dict2: [String: Any]?, status: DocumentStatus) -> Document {
		var data = dict1[kSecValueData as String] as! Data
		defer { let c = data.count; data.withUnsafeMutableBytes { memset_s($0.baseAddress, c, 0, c); return } }
		var keyType: PrivateKeyType? = nil; var privateKeyData: Data? = nil
		if let dict2 {
			keyType = PrivateKeyType(rawValue: dict2[kSecAttrType as String] as? String ?? PrivateKeyType.derEncodedP256.rawValue)!
			privateKeyData = (dict2[kSecValueData as String] as! Data)
		}
		return Document(id: dict1[kSecAttrAccount as String] as! String, docType: dict1[kSecAttrLabel as String] as? String ?? "", docDataType: DocDataType(rawValue: dict1[kSecAttrType as String] as? String ?? DocDataType.cbor.rawValue) ?? DocDataType.cbor, data: data, privateKeyType: keyType, privateKey: privateKeyData, createdAt: (dict1[kSecAttrCreationDate as String] as! Date), modifiedAt: dict1[kSecAttrModificationDate as String] as? Date, status: status)
	}
}

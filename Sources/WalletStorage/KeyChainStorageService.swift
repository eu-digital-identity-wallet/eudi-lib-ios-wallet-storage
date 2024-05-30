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
	public func loadDocument(id: String) throws -> Document? {
		guard let dict1 = try loadDocumentData(id: id, for: .doc) else { return nil }
		let dict2 = try loadDocumentData(id: id, for: .key)
		return makeDocument(dict1: dict1, dict2: dict2)
	}
		
	func loadDocumentData(id: String, for type: SavedKeyChainDataType) throws -> NSDictionary? {
		let query = makeQuery(id: id, for: type, bAll: false)
		var result: CFTypeRef?
		let status = SecItemCopyMatching(query as CFDictionary, &result)
		if status == errSecItemNotFound { return nil }
		let statusMessage = SecCopyErrorMessageString(status, nil) as? String
		guard status == errSecSuccess else {
			throw StorageError(description: statusMessage ?? "", code: Int(status))
		}
		return (result as! NSDictionary)
	}
	/// Gets all documents
	/// - Parameters:
	/// - Returns: The documents stored in keychain under the serviceName
	public func loadDocuments() throws -> [Document]? {
		guard let dicts1 = try loadDocumentsData(for: .doc) else { return nil }
		let dicts2 = try loadDocumentsData(for: .key)
		let documents = dicts1.compactMap { d1 in makeDocument(dict1: d1, dict2: dicts2?.first(where: { d2 in d1[kSecAttrAccount] as! String == d2[kSecAttrAccount] as! String})) }
		return documents
	}
	
	func loadDocumentsData(for type: SavedKeyChainDataType) throws -> [NSDictionary]? {
		let query = makeQuery(id: nil, for: type, bAll: true)
		var result: CFTypeRef?
		let status = SecItemCopyMatching(query as CFDictionary, &result)
		if status == errSecItemNotFound { return nil }
		let statusMessage = SecCopyErrorMessageString(status, nil) as? String
		guard status == errSecSuccess else {
			throw StorageError(description: statusMessage ?? "", code: Int(status))
		}
		return (result as! [NSDictionary])
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
	
	func serviceToSave(for dataToSaveType: SavedKeyChainDataType) -> String {
		switch dataToSaveType { case .key: serviceName + "_key"; default: serviceName }
	}

	public func saveDocumentData(_ document: Document, dataToSaveType: SavedKeyChainDataType, dataType: String, allowOverwrite: Bool = true) throws {
		// kSecAttrAccount is used to store the secret Id so that we can look it up later
		// kSecAttrService is always set to serviceName to enable us to lookup all our secrets later if needed
		guard dataType.count == 4 else { throw StorageError(description: "Invalid type") }
		if dataToSaveType == .key && document.privateKey == nil { throw StorageError(description: "Private key not available") }
		var query: [String: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: serviceToSave(for: dataToSaveType), kSecAttrAccount: document.id] as [String: Any]
		#if os(macOS)
		query[kSecUseDataProtectionKeychain as String] = true
	   #endif
		query[kSecValueData as String] = switch dataToSaveType { case .key: document.privateKey!; default: document.data }
		query[kSecAttrLabel as String] = document.docType
		query[kSecAttrType as String] = dataType
		var status = SecItemAdd(query as CFDictionary, nil)
		if allowOverwrite && status == errSecDuplicateItem {
			let updated = [kSecValueData: query[kSecValueData as String] as! Data, kSecAttrLabel: document.docType, kSecAttrType: dataType] as [String: Any]
			query = [kSecClass: kSecClassGenericPassword, kSecAttrService: serviceToSave(for: dataToSaveType), kSecAttrAccount: document.id] as [String: Any]
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
	public func deleteDocument(id: String) throws {
		try deleteDocumentData(id: id, for: .doc)
		try? deleteDocumentData(id: id, for: .key)
	}
	
	public func deleteDocumentData(id: String, for saveType: SavedKeyChainDataType) throws {
		let query: [String: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: serviceToSave(for: saveType), kSecAttrAccount: id] as [String: Any]
		let status = SecItemDelete(query as CFDictionary)
		let statusMessage = SecCopyErrorMessageString(status, nil) as? String
		guard status == errSecSuccess else { throw StorageError(description: statusMessage ?? "", code: Int(status)) 	}
	}
	
	/// Delete all documents from keychain
	/// - Parameters:
	///   - id: The Id of the secret
	public func deleteDocuments() throws {
		try deleteDocumentsData(for: .doc)
		try? deleteDocumentsData(for: .key)
	}
	
	public func deleteDocumentsData(for saveType: SavedKeyChainDataType) throws {
		// kSecAttrAccount is used to store the secret Id so that we can look it up later
		// kSecAttrService is always set to serviceName to enable us to lookup all our secrets later if needed
		// kSecAttrType is used to store the secret type to allow us to cast it to the right Type on search
		let query: [String: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: serviceToSave(for: saveType)] as [String: Any]
		let status = SecItemDelete(query as CFDictionary)
		let statusMessage = SecCopyErrorMessageString(status, nil) as? String
		guard status == errSecSuccess else {
			throw StorageError(description: statusMessage ?? "", code: Int(status))
		}
	}
	
	/// Make a query for a an item in keychain
	/// - Parameters:
	///   - id: id
	///   - bAll: request all matching items
	/// - Returns: The dictionary query
	func makeQuery(id: String?, for saveType: SavedKeyChainDataType, bAll: Bool) -> [String: Any] {
		guard id != nil || bAll else {	fatalError("Invalid call to makeQuery") }
		var query: [String: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: serviceToSave(for: saveType), kSecReturnData: true, kSecReturnAttributes: true] as [String: Any]
		if bAll { query[kSecMatchLimit as String] = kSecMatchLimitAll}
		if let id { query[kSecAttrAccount as String] = id}
		if let accessGroup, !accessGroup.isEmpty { query[kSecAttrAccessGroup as String] = accessGroup }
		return query
	}
	
	/// Make a document from a keychain item
	/// - Parameter dict: keychain item returned as dictionary
	/// - Returns: the document
	func makeDocument(dict1: NSDictionary, dict2: NSDictionary?) -> Document {
		var data = dict1[kSecValueData] as! Data
		defer { let c = data.count; data.withUnsafeMutableBytes { memset_s($0.baseAddress, c, 0, c); return } }
		var keyType: PrivateKeyType? = nil; var privateKeyData: Data? = nil
		if let dict2 {
			keyType = PrivateKeyType(rawValue: dict2[kSecAttrType] as? String ?? PrivateKeyType.derEncodedP256.rawValue)!
			privateKeyData = (dict2[kSecValueData] as! Data)
		}
		return Document(id: dict1[kSecAttrAccount] as! String, docType: dict1[kSecAttrLabel] as? String ?? "", docDataType: DocDataType(rawValue: dict1[kSecAttrType] as? String ?? DocDataType.cbor.rawValue)!, data: data, privateKeyType: keyType, privateKey: privateKeyData, createdAt: (dict1[kSecAttrCreationDate] as! Date), modifiedAt: dict1[kSecAttrModificationDate] as? Date)
	}
}

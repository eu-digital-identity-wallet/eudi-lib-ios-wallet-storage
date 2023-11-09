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

	public func loadDocument(id: String) throws -> Document? {
		let query = makeQuery(id: nil, bAll: false)
		var result: CFTypeRef?
		let status = SecItemCopyMatching(query as CFDictionary, &result)
		if status == errSecItemNotFound { return nil }
		let statusMessage = SecCopyErrorMessageString(status, nil) as? String
		guard status == errSecSuccess else {
			throw StorageError(description: statusMessage ?? "", code: Int(status))
		}
		let dict = result as! NSDictionary
		return makeDocument(dict: dict)
	}
	/// Gets the secret with the id passed in parameter
	/// - Parameters:
	///   - label: The label  (docType) of the secret
	/// - Returns: The secret
	public func loadDocuments() throws -> [Document]? {
		let query = makeQuery(id: nil, bAll: true)
		var result: CFTypeRef?
		let status = SecItemCopyMatching(query as CFDictionary, &result)
		if status == errSecItemNotFound { return nil }
		let statusMessage = SecCopyErrorMessageString(status, nil) as? String
		guard status == errSecSuccess else {
			throw StorageError(description: statusMessage ?? "", code: Int(status))
		}
		let dicts = result as! [NSDictionary]
		let documents = dicts.compactMap { makeDocument(dict: $0) }
		return documents
	}
	
	/// Save the secret to keychain
	/// Note: the value passed in will be zeroed out after the secret is saved
	/// - Parameters:
	///   - id: The Id of the secret
	///   - accessGroup: The access group to use to save secret.
	///   - value: The value of the secret
	///   - label: label of the document
	public func saveDocument(_ document: Document) throws {
		// kSecAttrAccount is used to store the secret Id so that we can look it up later
		// kSecAttrService is always set to serviceName to enable us to lookup all our secrets later if needed
		// kSecAttrType is used to store the secret type to allow us to cast it to the right Type on search
		var query: [String: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: serviceName, kSecAttrAccount: document.id] as [String: Any]
		#if os(macOS)
		query[kSecUseDataProtectionKeychain as String] = true
	   #endif
		query[kSecValueData as String] = document.data
		query[kSecAttrLabel as String] = document.docType
		var status = SecItemAdd(query as CFDictionary, nil)
		if status == errSecDuplicateItem {
			let updated = [kSecValueData: document.data, kSecAttrLabel: document.docType] as [String: Any]
			query = [kSecClass: kSecClassGenericPassword, kSecAttrService: serviceName, kSecAttrAccount: document.id] as [String: Any]
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
		// kSecAttrAccount is used to store the secret Id so that we can look it up later
		// kSecAttrService is always set to serviceName to enable us to lookup all our secrets later if needed
		// kSecAttrType is used to store the secret type to allow us to cast it to the right Type on search
		let query: [String: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: serviceName, kSecAttrAccount: id] as [String: Any]
		let status = SecItemDelete(query as CFDictionary)
		let statusMessage = SecCopyErrorMessageString(status, nil) as? String
		guard status == errSecSuccess else {
			throw StorageError(description: statusMessage ?? "", code: Int(status))
		}
	}
	
	/// Delete all documents from keychain
	/// Note: the value passed in will be zeroed out after the secret is deleted
	/// - Parameters:
	///   - id: The Id of the secret
	public func deleteDocuments() throws {
		// kSecAttrAccount is used to store the secret Id so that we can look it up later
		// kSecAttrService is always set to serviceName to enable us to lookup all our secrets later if needed
		// kSecAttrType is used to store the secret type to allow us to cast it to the right Type on search
		let query: [String: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: serviceName] as [String: Any]
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
	func makeQuery(id: String?, bAll: Bool) -> [String: Any] {
		var query: [String: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: serviceName,  kSecReturnData: true, kSecReturnAttributes: true] as [String: Any]
		if bAll { query[kSecMatchLimit as String] = kSecMatchLimitAll}
		if let id { query[kSecAttrAccount as String] = id}
		if let accessGroup, !accessGroup.isEmpty { query[kSecAttrAccessGroup as String] = accessGroup }
		return query
	}
	
	/// Make a document from a keychain item
	/// - Parameter dict: keychain item returned as dictionary
	/// - Returns: the document
	func makeDocument(dict: NSDictionary) -> Document {
		var data = dict[kSecValueData] as! Data
		defer { let c = data.count; data.withUnsafeMutableBytes { memset_s($0.baseAddress, c, 0, c); return } }
		return Document(id: dict[kSecAttrAccount] as? String ?? "", docType: dict[kSecAttrLabel] as? String ?? "", data: data, createdAt: dict[kSecAttrCreationDate] as! Date, modifiedAt: dict[kSecAttrModificationDate] as? Date)
	}
}

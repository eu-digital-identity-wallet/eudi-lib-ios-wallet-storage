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
	var vcService = "eudiw"
	var accessGroup: String?
	var issuerFetching: ()
	
	public init() {}
	
	/// Gets the secret with the id passed in parameter
	/// - Parameters:
	///   - label: The label  (docType) of the secret
	/// - Returns: The secret
	public func loadDocument(docType: String) throws -> Document? {
		let query = makeQuery(docType: docType, bAll: false)
		var result: CFTypeRef?
		let status = SecItemCopyMatching(query as CFDictionary, &result)
		if status == errSecItemNotFound { return nil }
		let statusMessage = SecCopyErrorMessageString(status, nil) as? String
		guard status == errSecSuccess else {
			throw NSError(domain: "\(KeyChainStorageService.self)", code: Int(status), userInfo: [NSLocalizedDescriptionKey: statusMessage ?? ""])
		}
		let dict = result as! NSDictionary
		return makeDocument(dict: dict)
	}
	
	public func loadDocuments() throws -> [Document]? {
		let query = makeQuery(docType: nil, bAll: true)
		var result: CFTypeRef?
		let status = SecItemCopyMatching(query as CFDictionary, &result)
		if status == errSecItemNotFound { return nil }
		let statusMessage = SecCopyErrorMessageString(status, nil) as? String
		guard status == errSecSuccess else {
			throw NSError(domain: "\(KeyChainStorageService.self)", code: Int(status), userInfo: [NSLocalizedDescriptionKey: statusMessage ?? ""])
		}
		let dicts = result as! [NSDictionary]
		let documents = dicts.compactMap { makeDocument(dict: $0) }
		return documents
	}
	
	func makeQuery(docType: String?, bAll: Bool) -> [String: Any] {
		var query: [String: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: vcService,  kSecReturnData: true, kSecReturnAttributes: true] as [String: Any]
		if bAll { query[kSecMatchLimit as String] = kSecMatchLimitAll}
		if let docType { query[kSecAttrAccount as String] = docType}
		if let accessGroup, !accessGroup.isEmpty { query[kSecAttrAccessGroup as String] = accessGroup }
		return query
	}
	
	func makeDocument(dict: NSDictionary) -> Document {
		var data = dict[kSecValueData] as! Data
		defer { let c = data.count; data.withUnsafeMutableBytes { memset_s($0.baseAddress, c, 0, c); return } }
		return Document(id: dict[kSecAttrLabel] as? String ?? "", docType: dict[kSecAttrAccount] as? String ?? "", data: data, createdAt: dict[kSecAttrCreationDate] as! Date, modifiedAt: dict[kSecAttrModificationDate] as? Date)
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
		// kSecAttrService is always set to vcService to enable us to lookup all our secrets later if needed
		// kSecAttrType is used to store the secret type to allow us to cast it to the right Type on search
		var query = makeQuery(docType: document.docType, bAll: false)
		#if os(macOS)
		query[kSecUseDataProtectionKeychain as String] = true
	   #endif
		
		query[kSecValueData as String] = document.data
		query[kSecAttrLabel as String] = document.id
		var status = SecItemAdd(query as CFDictionary, nil)
		if status == errSecDuplicateItem {
			let updated = [kSecValueData: document.data, kSecAttrLabel: document.id] as [String: Any]
			status = SecItemUpdate(makeQuery(docType: document.docType, bAll: false) as CFDictionary, updated as CFDictionary)
		}
		let statusMessage = SecCopyErrorMessageString(status, nil) as? String
		guard status == errSecSuccess else {
			throw NSError(domain: "\(KeyChainStorageService.self)", code: Int(status), userInfo: [NSLocalizedDescriptionKey: statusMessage ?? ""])
		}
	}
	
	/// Delete the secret from keychain
	/// Note: the value passed in will be zeroed out after the secret is deleted
	/// - Parameters:
	///   - id: The Id of the secret
	///   - itemTypeCode: The secret type code (4 chars)
	///   - accessGroup: The access group of the secret.
	public func deleteDocument(docType: String) throws {		
		// kSecAttrAccount is used to store the secret Id so that we can look it up later
		// kSecAttrService is always set to vcService to enable us to lookup all our secrets later if needed
		// kSecAttrType is used to store the secret type to allow us to cast it to the right Type on search
		let query = makeQuery(docType: docType, bAll: false)
		let status = SecItemDelete(query as CFDictionary)
		let statusMessage = SecCopyErrorMessageString(status, nil) as? String
		guard status == errSecSuccess else {
			throw NSError(domain: "\(KeyChainStorageService.self)", code: Int(status), userInfo: [NSLocalizedDescriptionKey: statusMessage ?? ""])
		}
	}
}

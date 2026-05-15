//
//  ks.swift
//  WalletStorage
//
//  Created by ffeli on 25/10/2024.
//

import Foundation
import MdocDataModel18013

public actor KeyChainSecureKeyStorage: SecureKeyStorage {
	public let serviceName: String
	public let accessGroup: String?
	var dict: [String: Data]?
	var keyOptions: KeyOptions?
	
	public init(serviceName: String, accessGroup: String?) {
		self.serviceName = serviceName
		self.accessGroup = accessGroup
	}
	
	static func keyChainDataValue(key: String, value: Any) -> (String, Data)? {
		if let stringValue = value as? String {
			let dataValue = stringValue.data(using: .utf8)!
			return (key, dataValue)
		}
		if let dataValue = value as? Data {
			return (key, dataValue)
		}
		return nil
	}
	
	public func readKeyInfo(id: String) throws -> [String : Data] {
		let keyInfoDictionaries = try KeyChainStorageService.loadData(
			serviceName: serviceName,
			accessGroup: accessGroup,
			id: id,
			status: .issued,
			dataToLoadType: .keyInfo
		)
		guard let keyInfoDictionaries, !keyInfoDictionaries.isEmpty else { return [:] }
		return Dictionary(
			uniqueKeysWithValues: keyInfoDictionaries.first!.compactMap(Self.keyChainDataValue)
		)
	}
	
	public func readKeyData(id: String, index: Int) throws -> [String : Data] {
		let keyDataIdentifier = "\(id)_\(index)"
		let keyDataDictionaries = try KeyChainStorageService.loadData(
			serviceName: serviceName,
			accessGroup: accessGroup,
			id: keyDataIdentifier,
			status: .issued,
			dataToLoadType: .key
		)
		guard let keyDataDictionaries, !keyDataDictionaries.isEmpty else { return [:] }
		return Dictionary(
			uniqueKeysWithValues: keyDataDictionaries.first!.compactMap(Self.keyChainDataValue)
		)
	}
	
	// save key public info
	public func writeKeyInfo(id: String, dict: [String: Data]) throws {
		self.dict = dict
		try KeyChainStorageService.saveDocumentData(
			serviceName: serviceName,
			accessGroup: accessGroup,
			id: id,
			status: .issued,
			dataType: .keyInfo,
			setDictValues: setDictValues1,
			allowOverwrite: true
		)
	}
	
	// save key batch info
	public func writeKeyDataBatch(
		id: String,
		startIndex: Int,
		dicts: [[String : Data]],
		keyOptions: MdocDataModel18013.KeyOptions?
	) async throws {
		guard dicts.count > 0 else { return }
		self.keyOptions = keyOptions
		for i in startIndex..<dicts.count+startIndex {
			self.dict = dicts[i]
			let keyDataIdentifier = "\(id)_\(i)"
			try KeyChainStorageService.saveDocumentData(
				serviceName: serviceName,
				accessGroup: accessGroup,
				id: keyDataIdentifier,
				status: .issued,
				dataType: .key,
				setDictValues: setDictValues2,
				allowOverwrite: true
			)
		}
	}
	
	// delete key info and data
	public func deleteKeyBatch(id: String, startIndex: Int, batchSize: Int) throws {
		logger.info("Delete key-batch with id \(id)")
		for index in startIndex..<batchSize+startIndex {
			let keyDataIdentifier = "\(id)_\(index)"
			try KeyChainStorageService.deleteDocumentData(
				serviceName: serviceName,
				accessGroup: accessGroup,
				id: keyDataIdentifier,
				docStatus: .issued,
				dataType: .key
			)
		}
	}
	
	public func deleteKeyInfo(id: String) throws {
		try KeyChainStorageService.deleteDocumentData(
			serviceName: serviceName,
			accessGroup: accessGroup,
			id: id,
			docStatus: .issued,
			dataType: .keyInfo
		)
	}
	
	// helper function to convert generic data dictionary to keychain expected dictionary
	func setDictValues1(_ d: inout [String: Any]) {
		guard let dict else { return }
		for (attributeName, attributeValue) in dict {
			let keychainValue: Any = if attributeName == kSecValueData as String {
				attributeValue
			} else {
				String(data: attributeValue, encoding: .utf8) ?? ""
			}
			d[attributeName] = keychainValue
		}
		d[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
	}
	
	// helper function to convert generic data dictionary to keychain expected dictionary.
	// Create access control value when key options are provided.
	func setDictValues2(_ d: inout [String: Any]) {
		guard let dict else { return }
		for (attributeName, attributeValue) in dict {
			let keychainValue: Any = if attributeName == kSecValueData as String {
				attributeValue
			} else {
				String(data: attributeValue, encoding: .utf8) ?? ""
			}
			d[attributeName] = keychainValue
		}
		let accessProtection =
			keyOptions?.accessProtection?.constant ?? kSecAttrAccessibleWhenUnlockedThisDeviceOnly
		let accessControlFlags = keyOptions?.accessControl?.flags ?? []
		let accessControl = SecAccessControlCreateWithFlags(nil, accessProtection, accessControlFlags, nil)!
		d[kSecAttrAccessControl as String] = accessControl as Any
	}

}


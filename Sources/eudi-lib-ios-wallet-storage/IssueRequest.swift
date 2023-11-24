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
import CryptoKit
import MdocDataModel18013

/// Issue request structure
public struct IssueRequest {
	public let id: String
	public let docType: String?
	public var keyData: Data?
	public let privateKeyType: PrivateKeyType
	
	/// Initialize issue request with id
	///
	/// - Parameters:
	///   - id: a key identifier (uuid)
	public init(id: String = UUID().uuidString, docType: String? = nil, privateKeyType: PrivateKeyType = .x963EncodedP256, keyData: Data? = nil) throws {
		self.id = id
		self.docType = docType
		self.privateKeyType = privateKeyType
		if let keyData {
			self.keyData = keyData
			return
		}
		if privateKeyType == .derEncodedP256 || privateKeyType == .pemStringDataP256 || privateKeyType == .x963EncodedP256 {
			let p256 = P256.Signing.PrivateKey()
			self.keyData = switch privateKeyType { case .derEncodedP256: p256.derRepresentation; case .pemStringDataP256: p256.pemRepresentation.data(using: .utf8)!; case .x963EncodedP256: p256.x963Representation; default: Data() }
		} else if privateKeyType == .secureEnclaveP256 {
			let secureEnclaveKey = try SecureEnclave.P256.Signing.PrivateKey()
			self.keyData = secureEnclaveKey.dataRepresentation
		} 
	}
	
	public func saveToStorage(_ storageService: any DataStorageService) throws {
		// save key data to storage with id
		let docKey = Document(id: id, docType: docType ?? "P256", docDataType: .cbor, data: Data(), privateKeyType: privateKeyType, privateKey: keyData, createdAt: Date())
		try storageService.saveDocument(docKey, allowOverwrite: true)
	}
	
	public mutating func loadFromStorage(_ storageService: any DataStorageService, id: String) throws {
		guard let doc = try storageService.loadDocument(id: id) else { return }
		keyData = doc.privateKey
	}
	
	public func toCoseKeyPrivate() throws -> CoseKeyPrivate {
		guard let keyData else { fatalError("Key data not loaded") }
		if privateKeyType == .derEncodedP256 || privateKeyType == .pemStringDataP256 || privateKeyType == .x963EncodedP256 {
			let p256 = switch privateKeyType { case .derEncodedP256: try P256.Signing.PrivateKey(derRepresentation: keyData); case .x963EncodedP256: try P256.Signing.PrivateKey(x963Representation: keyData); case .pemStringDataP256: try P256.Signing.PrivateKey(pemRepresentation: String(data: keyData, encoding: .utf8)!); default: P256.Signing.PrivateKey() }
			return CoseKeyPrivate(privateKeyx963Data: p256.x963Representation, crv: .p256)
		} else {
			let se256 = try SecureEnclave.P256.Signing.PrivateKey(dataRepresentation: keyData)
			return CoseKeyPrivate(publicKeyx963Data: se256.publicKey.x963Representation, secureEnclaveData: keyData)
		}
	}
	
	public func getPublicKeyPEM() throws -> String {
		guard let keyData else { fatalError("Key data not loaded") }
		if privateKeyType == .derEncodedP256 || privateKeyType == .pemStringDataP256 || privateKeyType == .x963EncodedP256 {
			let p256 = switch privateKeyType { case .derEncodedP256: try P256.Signing.PrivateKey(derRepresentation: keyData); case .x963EncodedP256: try P256.Signing.PrivateKey(x963Representation: keyData); case .pemStringDataP256: try P256.Signing.PrivateKey(pemRepresentation: String(data: keyData, encoding: .utf8)!); default: P256.Signing.PrivateKey() }
			return p256.publicKey.pemRepresentation
		} else {
			let se256 = try SecureEnclave.P256.Signing.PrivateKey(dataRepresentation: keyData)
			return se256.publicKey.pemRepresentation
		}
	}
}



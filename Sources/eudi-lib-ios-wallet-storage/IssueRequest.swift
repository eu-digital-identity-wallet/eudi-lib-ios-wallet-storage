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
	public var id: String
	public var docType: String?
	public var keyData: Data
	public var privateKeyType: PrivateKeyType
	
	/// Initialize issue request with id
	///
	/// - Parameters:
	///   - id: a key identifier (uuid)
	public init(id: String = UUID().uuidString, docType: String? = nil, privateKeyType: PrivateKeyType = .secureEnclaveP256, keyData: Data? = nil) throws {
		self.id = id
		self.docType = docType
		self.privateKeyType = privateKeyType
		if let keyData {
			self.keyData = keyData
			return
		}
		switch privateKeyType {
		case .derEncodedP256:
			let p256 = P256.KeyAgreement.PrivateKey()
			self.keyData = p256.derRepresentation
		case .pemStringDataP256:
			let p256 = P256.KeyAgreement.PrivateKey()
			self.keyData = p256.pemRepresentation.data(using: .utf8)!
		case .x963EncodedP256:
			let p256 = P256.KeyAgreement.PrivateKey()
			self.keyData = p256.x963Representation
		case .secureEnclaveP256:
			let secureEnclaveKey = try SecureEnclave.P256.KeyAgreement.PrivateKey() 
			self.keyData = secureEnclaveKey.dataRepresentation
		}
	}
	
	public func saveToStorage(_ storageService: any DataStorageService) throws {
		// save key data to storage with id
		let docKey = Document(id: id, docType: docType ?? "P256", docDataType: .cbor, data: Data(), privateKeyType: privateKeyType, privateKey: keyData, createdAt: Date())
		try storageService.saveDocument(docKey, allowOverwrite: true)
	}
	
	public init?(_ storageService: any DataStorageService, id: String) throws {
		guard let doc = try storageService.loadDocument(id: id), let pk = doc.privateKey, let pkt = doc.privateKeyType else { return nil }
		self.id = id
		keyData = pk
		privateKeyType = pkt
	}
	
	public func toCoseKeyPrivate() throws -> CoseKeyPrivate {
		switch privateKeyType {
		case .derEncodedP256:
			let p256 = try P256.KeyAgreement.PrivateKey(derRepresentation: keyData)
			return CoseKeyPrivate(privateKeyx963Data: p256.x963Representation, crv: .p256)
		case .x963EncodedP256:
			let p256 = try P256.KeyAgreement.PrivateKey(x963Representation: keyData)
			return CoseKeyPrivate(privateKeyx963Data: p256.x963Representation, crv: .p256)
		case .pemStringDataP256:
			let p256 = try P256.KeyAgreement.PrivateKey(pemRepresentation: String(data: keyData, encoding: .utf8)!)
			return CoseKeyPrivate(privateKeyx963Data: p256.x963Representation, crv: .p256)
		case .secureEnclaveP256:
			let se256 = try SecureEnclave.P256.KeyAgreement.PrivateKey(dataRepresentation: keyData)
			return CoseKeyPrivate(publicKeyx963Data: se256.publicKey.x963Representation, secureEnclaveKeyID: keyData)
		}
	}
	
	public func getPublicKeyPEM() throws -> String {
		switch privateKeyType {
		case .derEncodedP256:
			let p256 = try P256.KeyAgreement.PrivateKey(derRepresentation: keyData)
			return p256.publicKey.pemRepresentation
		case .pemStringDataP256:
			let p256 = try P256.KeyAgreement.PrivateKey(pemRepresentation: String(data: keyData, encoding: .utf8)!)
			return p256.publicKey.pemRepresentation
		case .x963EncodedP256:
			let p256 = try P256.KeyAgreement.PrivateKey(x963Representation: keyData)
			return p256.publicKey.pemRepresentation
		case .secureEnclaveP256:
			let se256 = try SecureEnclave.P256.KeyAgreement.PrivateKey(dataRepresentation: keyData)
			return se256.publicKey.pemRepresentation
		}
	}
	
}



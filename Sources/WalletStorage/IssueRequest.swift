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
public struct IssueRequest: Sendable {
	public var id: String
	public var docType: String?
	public var secureAreaName: String?
	public var coseKeyPrivate: CoseKeyPrivate?
	/// Initialize issue request with id
	///
	/// - Parameters:
	///   - id: a key identifier (uuid)
	public init(id: String = UUID().uuidString, docType: String? = nil, secureAreaName: String? = nil) throws {
		self.id = id
		self.docType = docType
		self.secureAreaName = secureAreaName
		/*
		if let keyData {
			self.keyData = keyData
			// key-data already created, exit
			return
		}
		switch privateKeyType {
		case .x963EncodedP256:
			let p256 = P256.KeyAgreement.PrivateKey()
			self.keyData = p256.x963Representation
		case .secureEnclaveP256:
			let secureEnclaveKey = try SecureEnclave.P256.KeyAgreement.PrivateKey() 
			self.keyData = secureEnclaveKey.dataRepresentation
		}
		logger.info("Created private key of type \(privateKeyType)")
		if let docType { logger.info(" and docType: \(docType)") }
		*/
	}
	
	public func saveTo(storageService: any DataStorageService, status: DocumentStatus) async throws {
		// save key data to storage with id
		logger.info("Saving Issue request with id: \(id) and document status: \(status)")
		//let docKey = Document(id: id, docType: docType ?? "P256", docDataType: .cbor, data: Data(), privateKeyType: privateKeyType, privateKey: keyData, createdAt: Date(), displayName: nil, status: status)
		//try await storageService.saveDocument(docKey, allowOverwrite: true)
	}

	/*
	public func toCoseKeyPrivate() throws -> CoseKeyPrivate {
		switch privateKeyType {
		case .x963EncodedP256:
			let p256 = try P256.KeyAgreement.PrivateKey(x963Representation: keyData)
			return CoseKeyPrivate(privateKeyx963Data: p256.x963Representation, crv: .P256)
		case .secureEnclaveP256:
			let se256 = try SecureEnclave.P256.KeyAgreement.PrivateKey(dataRepresentation: keyData)
			return CoseKeyPrivate(publicKeyx963Data: se256.publicKey.x963Representation, secureEnclaveKeyID: keyData)
		}
	}
	*/
	
	
}



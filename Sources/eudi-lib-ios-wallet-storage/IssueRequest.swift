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

/// Issue request structure
public struct IssueRequest {
	#if os(iOS)
	let secureKey: SecureEnclave.P256.Signing.PrivateKey
	/// DER representation of public key
	public var publicKeyDer: Data { secureKey.publicKey.derRepresentation }
	/// PEM representation of public key
	public var publicKeyPEM: String { secureKey.publicKey.pemRepresentation }
	/// X963 representation of public key
	public var publicKeyX963: Data { secureKey.publicKey.x963Representation }
	#endif

	/// Initialize issue request
	/// - Parameters:
	///   - savedKey: saved key representation (optional)
	public init(savedKey: Data? = nil) throws {
	#if os(iOS)
		secureKey = if let savedKey { try SecureEnclave.P256.Signing.PrivateKey(dataRepresentation: savedKey) } else { try SecureEnclave.P256.Signing.PrivateKey() }
	#endif
	}
	
	/// Initialize issue request with id
	///
	/// - Parameters:
	///   - id: a key identifier (uuid)
	public init(id: String, storageService: any DataStorageService) throws {
	#if os(iOS)
		secureKey = try SecureEnclave.P256.Signing.PrivateKey() 
		let docKey = Document(id: id, docType: "P256", data: secureKey.dataRepresentation, createdAt: Date())
		try storageService.saveDocument(docKey)
	#endif
	}
	
	#if os(iOS)
	/// Sign data with ``secureKey``
	/// - Parameter data: Data to be signed
	/// - Returns: DER representation of signture for SHA256  hash
	func signData(_ data: Data) throws -> Data {
		let signature: P256.Signing.ECDSASignature = try secureKey.signature(for: SHA256.hash(data: data))
		return signature.derRepresentation
	}
	#endif
	//func certificateTrust(certificate: SecCertificate) -> ver
}



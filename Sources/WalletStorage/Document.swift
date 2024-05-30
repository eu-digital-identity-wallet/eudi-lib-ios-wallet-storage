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

/// wallet document structure
public struct Document {
	public init(id: String = UUID().uuidString, docType: String, docDataType: DocDataType, data: Data, privateKeyType: PrivateKeyType?, privateKey: Data?, createdAt: Date?, modifiedAt: Date? = nil) {
		self.id = id
		self.docType = docType
		self.docDataType = docDataType
		self.data = data
		self.privateKeyType = privateKeyType
		self.privateKey = privateKey
		self.createdAt = createdAt ?? Date()
		self.modifiedAt = modifiedAt
	}
	
	public var id: String = UUID().uuidString
	public let docType: String
	public let data: Data
	public let docDataType: DocDataType
	public let privateKeyType: PrivateKeyType?
	public let privateKey: Data?
	public let createdAt: Date
	public let modifiedAt: Date?
	
	/// get CBOR data and private key from document
	public func getCborData() -> (iss: (String, IssuerSigned), dpk: (String, CoseKeyPrivate))? {
		switch docDataType {
		case .signupResponseJson:
			guard let sr = data.decodeJSON(type: SignUpResponse.self), let dr = sr.deviceResponse, let iss = dr.documents?.first?.issuerSigned, let dpk = sr.devicePrivateKey else { return nil }
			let randomId = UUID().uuidString
			return ((randomId, iss), (randomId, dpk))
		case .cbor:
			guard let iss = IssuerSigned(data: [UInt8](data)), let privateKeyType, let privateKey, let dpk = try? IssueRequest(id: id, privateKeyType: privateKeyType, keyData: privateKey).toCoseKeyPrivate() else { return nil }
			return ((id, iss), (id, dpk))
		case .sjwt:
			fatalError("Format \(docDataType) not implemented")
		}
	}
}

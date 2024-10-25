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
public struct Document: DocumentProtocol, Sendable {
	public init(id: String = UUID().uuidString, docType: String, docDataType: DocDataType, data: Data, secureAreaName: String?, createdAt: Date?, modifiedAt: Date? = nil, displayName: String?, status: DocumentStatus) {
		self.id = id
		self.docType = docType
		self.docDataType = docDataType
		self.data = data
		self.secureAreaName = secureAreaName
		self.createdAt = createdAt ?? Date()
		self.modifiedAt = modifiedAt
		self.displayName = displayName
		self.status = status
	}
	
	public var id: String = UUID().uuidString
	public let docType: String
	public let data: Data
	public let docDataType: DocDataType
	public let secureAreaName: String?
	public let createdAt: Date
	public let modifiedAt: Date?
	public let displayName: String?
	public let status: DocumentStatus
	public var statusDescription: String? {	status.rawValue	}
	public var isDeferred: Bool { status == .deferred }
	
	/// get CBOR data and private key from document
	public func getCborData() -> (iss: (String, IssuerSigned), dpk: (String, CoseKeyPrivate))? {
		switch docDataType {
		case .cbor:
			guard let iss = IssuerSigned(data: [UInt8](data)), let dpk = try? CoseKeyPrivate(key: nil, privateKeyId: id, secureArea: SecureAreaRegistry.shared.get(name: secureAreaName)) else { return nil }
			return ((id, iss), (id, dpk))
		case .sjwt:
			fatalError("Format \(docDataType) not implemented")
		}
	}
}

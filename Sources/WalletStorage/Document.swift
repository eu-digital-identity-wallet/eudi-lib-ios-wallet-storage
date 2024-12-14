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
public struct Document: Sendable {
	public init(id: String = UUID().uuidString, docType: String?, docDataFormat: DocDataFormat, data: Data, secureAreaName: String?, createdAt: Date?, modifiedAt: Date? = nil, metadata: Data?, status: DocumentStatus) {
		self.id = id
		self.docType = docType
		self.docDataFormat = docDataFormat
		self.data = data
		self.secureAreaName = secureAreaName
		self.createdAt = createdAt ?? Date()
		self.modifiedAt = modifiedAt
		self.metadata = metadata
		self.status = status
	}
	
	public var id: String = UUID().uuidString
	public let docType: String?
	public let data: Data
	public let docDataFormat: DocDataFormat
	public let secureAreaName: String?
	public let createdAt: Date
	public let modifiedAt: Date?
	public let metadata: Data?
	public let status: DocumentStatus
	public var statusDescription: String? {	status.rawValue	}
	public var isDeferred: Bool { status == .deferred }
	
	public func getDataForTransfer() -> (doc: (String, Data), fmt: (String, String), sa: (String, String))? {
		guard let sa = secureAreaName else { return nil }
		return ((id, data), (id, docDataFormat.rawValue), (id, sa))
	}

}

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
	public let id: String
	public let credentialOptions: CredentialOptions
	public var keyOptions: KeyOptions?
	public var secureArea: SecureArea
	public var secureAreaName: String { type(of: secureArea).name }
	/// Initialize issue request with id
	///
	/// - Parameters:
	///   - id: a key identifier (uuid)
	public init(id: String = UUID().uuidString, credentialOptions: CredentialOptions, keyOptions: KeyOptions? = nil) throws {
		self.id = id
		self.credentialOptions = credentialOptions
		self.keyOptions = keyOptions
		secureArea = SecureAreaRegistry.shared.get(name: keyOptions?.secureAreaName)
	}

	public func createKeyBatch() async throws -> [CoseKey] {
		let res = try await secureArea.createKeyBatch(id: id, credentialOptions: credentialOptions, keyOptions: keyOptions)
		return res
	}

}



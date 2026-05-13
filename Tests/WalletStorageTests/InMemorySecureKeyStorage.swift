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

/// In-memory implementation of SecureKeyStorage for testing purposes
public actor InMemorySecureKeyStorage: SecureKeyStorage {
	
	private var keyInfoStorage: [String: [String: Data]] = [:]
	private var keyDataStorage: [String: [String: Data]] = [:]
	
	public init() {}
	
	/// Read key public info
	public func readKeyInfo(id: String) async throws -> [String: Data] {
		return keyInfoStorage[id] ?? [:]
	}
	
	/// Read key sensitive info (may trigger biometric or password checks in real implementation)
	public func readKeyData(id: String, index: Int) async throws -> [String: Data] {
		let key = makeKeyDataKey(id: id, index: index)
		return keyDataStorage[key] ?? [:]
	}
	
	/// Save key public info
	public func writeKeyInfo(id: String, dict: [String: Data]) async throws {
		keyInfoStorage[id] = dict
	}
	
	/// Save key data batch info
	public func writeKeyDataBatch(id: String, startIndex: Int, dicts: [[String: Data]], keyOptions: KeyOptions?) async throws {
		for (offset, dict) in dicts.enumerated() {
			let index = startIndex + offset
			let key = makeKeyDataKey(id: id, index: index)
			keyDataStorage[key] = dict
		}
	}
	
	/// Delete key data batch
	public func deleteKeyBatch(id: String, startIndex: Int, batchSize: Int) async throws {
		for index in startIndex..<(startIndex + batchSize) {
			let key = makeKeyDataKey(id: id, index: index)
			keyDataStorage.removeValue(forKey: key)
		}
	}
	
	/// Delete key info
	public func deleteKeyInfo(id: String) async throws {
		keyInfoStorage.removeValue(forKey: id)
	}
	
	// MARK: - Helper Methods
	
	private func makeKeyDataKey(id: String, index: Int) -> String {
		return "\(id)_\(index)"
	}
	
	/// Clear all stored data (useful for testing)
	public func clearAll() {
		keyInfoStorage.removeAll()
		keyDataStorage.removeAll()
	}
	
	/// Get all stored key IDs (useful for testing)
	public func getAllKeyInfoIds() -> [String] {
		return Array(keyInfoStorage.keys)
	}
	
	/// Get all stored key data IDs (useful for testing)
	public func getAllKeyDataKeys() -> [String] {
		return Array(keyDataStorage.keys)
	}
}

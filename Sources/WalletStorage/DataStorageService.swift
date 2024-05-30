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

/// Data storage protocol
public protocol DataStorageService {
	var serviceName: String { get set }
	var accessGroup: String? { get set }
	func loadDocument(id: String) throws -> Document?
	func loadDocuments() throws -> [Document]?
	func saveDocument(_ document: Document, allowOverwrite: Bool) throws
	func saveDocumentData(_ document: Document, dataToSaveType: SavedKeyChainDataType, dataType: String, allowOverwrite: Bool) throws 
	func deleteDocument(id: String) throws
	func deleteDocuments() throws
}

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
public protocol DataStorageService: Actor {
	/// load a document with the specified id. If a batch of documents has been saved, the least used instance is loaded
	func loadDocument(id: String, status: DocumentStatus) async throws -> Document?
	/// load the placeholder documents for display
	func loadDocuments(status: DocumentStatus) async throws -> [Document]?
	/// save a document and optionally a batch of documents with different corresponding private keys
	func saveDocument(_ document: Document, batch: [Document]?, allowOverwrite: Bool) async throws
	/// delete a document and the batch of credentials and keys with the specified id and status
	func deleteDocument(id: String, status: DocumentStatus) async throws
	/// delete all documents (and keys) with the specified status
	func deleteDocuments(status: DocumentStatus) async throws
	/// delete document credential at a specified index
	func deleteDocumentCredential(id: String, index: Int) async throws
}

 /*
 * Copyright (c) 2023 European Commission
 *
 * Licensed under the EUPL, Version 1.2 or - as soon they will be approved by the European
 * Commission - subsequent versions of the EUPL (the "Licence"); You may not use this work
 * except in compliance with the Licence.
 *
 * You may obtain a copy of the Licence at:
 * https://joinup.ec.europa.eu/software/page/eupl
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the Licence is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the Licence for the specific language
 * governing permissions and limitations under the Licence.
 */

import Foundation

/// Data storage protocol
public protocol DataStorageService {
	var serviceName: String { get set }
	var accessGroup: String? { get set }
	func loadDocument(id: String) throws -> Document?
	func loadDocuments() throws -> [Document]?
	func saveDocument(_ document: Document) throws
	func deleteDocument(id: String) throws
	func deleteDocuments() throws
}

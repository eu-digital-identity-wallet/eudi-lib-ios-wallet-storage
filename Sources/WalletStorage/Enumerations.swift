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

/// Type of data to save in storage
/// ``doc``: Document data
/// ``key``: Private-key
///
/// Raw value must be a 4-length string due to keychain requirements
public enum SavedKeyChainDataType: String, Sendable, CaseIterable {
	case doc = "sdoc"
	case key = "skey"
	case keyInfo = "skei"
}

/// Format of document data
/// ``cbor``: DeviceResponse cbor encoded
/// ``sdjwt``: sd-jwt
/// 
/// Raw value must be a 4-length string due to keychain requirements
public enum DocDataFormat: String, Sendable, Codable {
	case cbor = "cbor"
	case sdjwt = "sjwt"
}


/// document status
public enum DocumentStatus: String, CaseIterable, Sendable {
	case issued
	case deferred
	case pending
}

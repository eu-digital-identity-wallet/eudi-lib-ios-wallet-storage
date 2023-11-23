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

/// type of data to save in storage
public enum SavedKeyChainDataType{
	case doc
	case key
}

/// Format of document data
/// ``cbor``: DeviceResponse cbor encoded
/// ``sjwt``: sd-jwt ** not yet supported **
/// ``signupResponseJson``: DeviceResponse and PrivateKey json serialized
public enum DocDataType: String  {
	case cbor = "cbor"
	case sjwt = "sjwt"
	case signupResponseJson = "srjs"
}

/// Format of private key
/// ``derEncodedP256``: DER encoded
/// ``pemStringDataP256`` PEM string encoded as utf8
/// ``x963EncodedP256``: ANSI x9.63 representation (default)
/// ``secureEnclaveP256``: data representation for the secure enclave
public enum PrivateKeyType: String {
	case derEncodedP256 = "dep2"
	case pemStringDataP256 = "pep2"
	case x963EncodedP256 = "x9p2"
	case secureEnclaveP256 = "sep2"
}

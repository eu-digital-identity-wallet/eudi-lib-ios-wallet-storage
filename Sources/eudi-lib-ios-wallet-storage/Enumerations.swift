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

public enum SavedKeyChainDataType{
	case doc
	case key
}
public enum DocDataType: String  {
	case cbor = "cbor"
	case sjwt = "sjwt"
	case signupResponseJson = "srjs"
}

public enum PrivateKeyType: String {
	case derEncodedP256 = "dep2"
	case pemStringDataP256 = "pep2"
	case x963EncodedP256 = "x9p2"
	case secureEnclaveP256 = "sep2"
}

import XCTest
import Foundation
@testable import WalletStorage
import MdocDataModel18013
import MdocSecurity18013

final class WalletStorageTests: XCTestCase {
	
		
    func testIssueRequestPublicKey() throws {
			SecureAreaRegistry.shared
				.register(secureArea: SampleDataSecureArea(storage: KeyChainSecureKeyStorage(serviceName: "test", accessGroup: nil)))
       let ir = try IssueRequest()
			XCTAssertNotNil(try ir.createKey())
    }

	
		
}

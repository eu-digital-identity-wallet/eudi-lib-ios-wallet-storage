import XCTest
import Foundation
@testable import WalletStorage
import MdocDataModel18013

final class WalletStorageTests: XCTestCase {
	
		
    func testIssueRequestPublicKey() throws {
       let ir = try IssueRequest()
       let pem = try ir.getPublicKeyPEM()
       XCTAssert(Bool(pem.count > 0))
       print(pem)
    }

	
		
}

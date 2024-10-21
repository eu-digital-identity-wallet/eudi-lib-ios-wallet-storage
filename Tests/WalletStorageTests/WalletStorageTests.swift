import XCTest
import Foundation
@testable import WalletStorage
import MdocDataModel18013

final class WalletStorageTests: XCTestCase {
	
		
    func testIssueRequestPublicKey() throws {
       let ir = try IssueRequest()
			XCTAssert(ir.keyData.count > 0)
    }

	
		
}

import XCTest
@testable import WalletStorage

final class eudi_lib_ios_wallet_storageTests: XCTestCase {
    func testIssueRequestPublicKey() throws {
       let ir = try IssueRequest()
       let pem = try ir.getPublicKeyPEM()
       XCTAssert(Bool(pem.count > 0))
       print(pem)
    }
}

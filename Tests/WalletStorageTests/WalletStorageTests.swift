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
	
	func testLoadPidIssuerSigned() {
		let base64str = String(data: Data(name: "eu_pid_base64", ext: "txt", from: Bundle.module)!, encoding: .utf8)!
		let pidIssueredSignedData = [UInt8](Data(base64URLEncoded: base64str.trimmingCharacters(in: .whitespacesAndNewlines))!)
		let pidIssueredSigned = IssuerSigned(data: pidIssueredSignedData)
		XCTAssertEqual(EuPidModel.euPidDocType, pidIssueredSigned?.issuerNameSpaces?.nameSpaces.map(\.key).first, "Test data contains PID doc type")
	}
	
		
}

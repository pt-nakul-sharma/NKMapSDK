import XCTest
@testable import NKWalk

final class NKWalkTests: XCTestCase {

    override func setUp() {
        super.setUp()
        NKWalk.shutdown()
    }

    override func tearDown() {
        NKWalk.shutdown()
        super.tearDown()
    }

    func testInitializationWithInvalidAPIKey() {
        let expectation = self.expectation(description: "Initialize with invalid key")

        NKWalk.initialize(apiKey: "") { result in
            switch result {
            case .success:
                XCTFail("Should not succeed with empty API key")
            case .failure(let error):
                if case .invalidAPIKey = error {
                    XCTAssertTrue(true)
                } else {
                    XCTFail("Wrong error type: \(error)")
                }
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0)
    }

    func testIsInitializedBefore() {
        XCTAssertFalse(NKWalk.isInitialized)
    }

    func testStartTrackingBeforeInit() {
        XCTAssertThrowsError(try NKWalk.startTracking()) { error in
            guard let nkError = error as? NKWalkError else {
                XCTFail("Wrong error type")
                return
            }

            if case .notInitialized = nkError {
                XCTAssertTrue(true)
            } else {
                XCTFail("Wrong error case: \(nkError)")
            }
        }
    }

    func testStopTrackingBeforeStart() {
        NKWalk.stopTracking()
        XCTAssertFalse(NKWalk.isTracking)
    }
}

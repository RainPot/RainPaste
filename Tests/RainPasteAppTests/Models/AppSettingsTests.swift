import XCTest
@testable import RainPasteApp

final class AppSettingsTests: XCTestCase {
    func testDefaultSettingsMatchProductExpectation() {
        let settings = AppSettings.defaultValue

        XCTAssertEqual(settings.maxHistoryCount, 200)
        XCTAssertTrue(settings.ignoresConsecutiveDuplicates)
        XCTAssertTrue(settings.closesWindowAfterCopy)
    }
}

import XCTest
@testable import RainPasteApp

@MainActor
final class MenuBarControllerTests: XCTestCase {
    func testStatusItemImageUsesTemplateRendering() throws {
        let image = try XCTUnwrap(MenuBarController.makeStatusItemImage())

        XCTAssertTrue(image.isTemplate)
    }
}

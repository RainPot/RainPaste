import XCTest
@testable import RainPasteApp

final class ClipboardItemTests: XCTestCase {
    func testPinnedItemsSortBeforeRecentItems() {
        let recent = ClipboardItem.make(
            content: "recent",
            createdAt: Date(timeIntervalSince1970: 200),
            isPinned: false
        )
        let pinned = ClipboardItem.make(
            content: "pinned",
            createdAt: Date(timeIntervalSince1970: 100),
            isPinned: true
        )

        let sorted = ClipboardItem.sortForDisplay([recent, pinned])

        XCTAssertEqual(sorted.map(\.content), ["pinned", "recent"])
    }
}

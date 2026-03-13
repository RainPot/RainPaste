import XCTest
@testable import RainPasteApp

@MainActor
final class ClipboardHistoryStoreTests: XCTestCase {
    func testAddItemDropsOldestUnpinnedItemsBeyondLimit() {
        let store = ClipboardHistoryStore(
            settings: AppSettings(
                maxHistoryCount: 2,
                ignoresConsecutiveDuplicates: true,
                closesWindowAfterCopy: true
            )
        )

        store.ingest("first", at: Date(timeIntervalSince1970: 1))
        store.ingest("second", at: Date(timeIntervalSince1970: 2))
        store.ingest("third", at: Date(timeIntervalSince1970: 3))

        XCTAssertEqual(store.items.map(\.content), ["third", "second"])
    }

    func testIngestSkipsConsecutiveDuplicateWhenEnabled() {
        let store = ClipboardHistoryStore(settings: .defaultValue)

        store.ingest("repeat", at: Date(timeIntervalSince1970: 1))
        store.ingest("repeat", at: Date(timeIntervalSince1970: 2))

        XCTAssertEqual(store.items.map(\.content), ["repeat"])
    }

    func testPinMovesItemAheadOfRecentItems() {
        let store = ClipboardHistoryStore(settings: .defaultValue)
        store.ingest("one", at: Date(timeIntervalSince1970: 1))
        store.ingest("two", at: Date(timeIntervalSince1970: 2))

        let oneID = try! XCTUnwrap(store.items.last?.id)
        store.setPinned(oneID, isPinned: true)

        XCTAssertEqual(store.items.map(\.content), ["one", "two"])
    }
}

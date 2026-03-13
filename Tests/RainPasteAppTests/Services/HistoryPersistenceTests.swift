import XCTest
@testable import RainPasteApp

final class HistoryPersistenceTests: XCTestCase {
    func testPersistenceRoundTripRestoresPinnedState() throws {
        let persistence = HistoryPersistence(fileURL: temporaryFileURL())
        let items = [ClipboardItem.make(content: "hello", isPinned: true)]

        try persistence.save(items: items, settings: .defaultValue)
        let snapshot = try persistence.load()

        XCTAssertEqual(snapshot.items.first?.isPinned, true)
        XCTAssertEqual(snapshot.items.first?.content, "hello")
    }

    func testMissingFileReturnsDefaultSnapshot() throws {
        let persistence = HistoryPersistence(fileURL: temporaryFileURL())

        let snapshot = try persistence.load()

        XCTAssertEqual(snapshot.items, [])
        XCTAssertEqual(snapshot.settings, .defaultValue)
    }

    private func temporaryFileURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
    }
}

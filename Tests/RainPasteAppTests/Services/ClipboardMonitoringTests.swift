import XCTest
@testable import RainPasteApp

@MainActor
final class ClipboardMonitoringTests: XCTestCase {
    func testMonitorIngestsOnlyNewClipboardText() {
        let pasteboard = FakePasteboard(changeSequence: [
            .init(changeCount: 1, text: "A"),
            .init(changeCount: 1, text: "A"),
            .init(changeCount: 2, text: "B"),
        ])
        let store = ClipboardHistoryStore(settings: .defaultValue)
        let monitor = ClipboardMonitoring(pasteboard: pasteboard, store: store)

        monitor.poll()
        monitor.poll()
        monitor.poll()

        XCTAssertEqual(store.items.map(\.content), ["B", "A"])
    }

    func testWriteDelegatesToPasteboardClient() {
        let pasteboard = FakePasteboard(changeSequence: [.init(changeCount: 0, text: nil)])
        let store = ClipboardHistoryStore(settings: .defaultValue)
        let monitor = ClipboardMonitoring(pasteboard: pasteboard, store: store)

        monitor.write("from-history")

        XCTAssertEqual(pasteboard.writtenTexts, ["from-history"])
    }
}

private final class FakePasteboard: SystemPasteboard {
    struct Snapshot {
        let changeCount: Int
        let text: String?
    }

    private let changeSequence: [Snapshot]
    private var readIndex = 0
    private var activeSnapshot: Snapshot?
    private(set) var writtenTexts: [String] = []

    init(changeSequence: [Snapshot]) {
        self.changeSequence = changeSequence
    }

    var changeCount: Int {
        let snapshot = currentSnapshot
        activeSnapshot = snapshot
        if readIndex < changeSequence.count - 1 {
            readIndex += 1
        }
        return snapshot.changeCount
    }

    func currentText() -> String? {
        activeSnapshot?.text
    }

    func write(text: String) {
        writtenTexts.append(text)
    }

    private var currentSnapshot: Snapshot {
        changeSequence[min(readIndex, changeSequence.count - 1)]
    }
}

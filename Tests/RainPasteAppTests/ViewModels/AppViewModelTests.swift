import XCTest
@testable import RainPasteApp

@MainActor
final class AppViewModelTests: XCTestCase {
    func testSearchReturnsMatchingItemsInDisplayOrder() {
        let store = ClipboardHistoryStore(items: [
            ClipboardItem.make(content: "git status", createdAt: Date(timeIntervalSince1970: 1)),
            ClipboardItem.make(content: "swift build", createdAt: Date(timeIntervalSince1970: 2)),
            ClipboardItem.make(content: "npm run dev", createdAt: Date(timeIntervalSince1970: 3), isPinned: true),
        ])
        let viewModel = AppViewModel(
            store: store,
            shortcutLabel: "⌘⌥V",
            onCopy: { _ in },
            onTogglePinned: { _ in },
            onDelete: { _ in },
            onClearAll: {}
        )

        viewModel.searchText = "sw"

        XCTAssertEqual(viewModel.filteredItems.map(\.content), ["swift build"])
    }

    func testBlankSearchReturnsAllItems() {
        let store = ClipboardHistoryStore(items: [
            ClipboardItem.make(content: "git status", createdAt: Date(timeIntervalSince1970: 1)),
            ClipboardItem.make(content: "swift build", createdAt: Date(timeIntervalSince1970: 2)),
        ])
        let viewModel = AppViewModel(
            store: store,
            shortcutLabel: "⌘⌥V",
            onCopy: { _ in },
            onTogglePinned: { _ in },
            onDelete: { _ in },
            onClearAll: {}
        )

        XCTAssertEqual(viewModel.filteredItems.map(\.content), ["swift build", "git status"])
    }

    func testClosePanelTriggersDismissAction() {
        let store = ClipboardHistoryStore(items: [])
        var didClose = false
        let viewModel = AppViewModel(
            store: store,
            shortcutLabel: "⌘⇧V",
            onCopy: { _ in },
            onTogglePinned: { _ in },
            onDelete: { _ in },
            onClearAll: {},
            onToggleMonitoring: {},
            onClose: { didClose = true }
        )

        viewModel.closePanel()

        XCTAssertTrue(didClose)
    }

    func testInitialSelectionDefaultsToFirstItem() throws {
        let store = ClipboardHistoryStore(items: [
            ClipboardItem.make(content: "git status", createdAt: Date(timeIntervalSince1970: 1)),
            ClipboardItem.make(content: "swift build", createdAt: Date(timeIntervalSince1970: 2)),
        ])
        let viewModel = AppViewModel(
            store: store,
            shortcutLabel: "⌘⇧V",
            onCopy: { _ in },
            onTogglePinned: { _ in },
            onDelete: { _ in },
            onClearAll: {}
        )

        XCTAssertEqual(viewModel.selectedItemID, try XCTUnwrap(viewModel.filteredItems.first?.id))
    }

    func testMoveSelectionDownAndUp() throws {
        let store = ClipboardHistoryStore(items: [
            ClipboardItem.make(content: "git status", createdAt: Date(timeIntervalSince1970: 1)),
            ClipboardItem.make(content: "swift build", createdAt: Date(timeIntervalSince1970: 2)),
            ClipboardItem.make(content: "npm run dev", createdAt: Date(timeIntervalSince1970: 3)),
        ])
        let viewModel = AppViewModel(
            store: store,
            shortcutLabel: "⌘⇧V",
            onCopy: { _ in },
            onTogglePinned: { _ in },
            onDelete: { _ in },
            onClearAll: {}
        )

        viewModel.moveSelection(delta: 1)
        XCTAssertEqual(viewModel.selectedItemID, try XCTUnwrap(viewModel.filteredItems[safe: 1]?.id))

        viewModel.moveSelection(delta: 1)
        XCTAssertEqual(viewModel.selectedItemID, try XCTUnwrap(viewModel.filteredItems[safe: 2]?.id))

        viewModel.moveSelection(delta: 1)
        XCTAssertEqual(viewModel.selectedItemID, try XCTUnwrap(viewModel.filteredItems.last?.id))

        viewModel.moveSelection(delta: -1)
        XCTAssertEqual(viewModel.selectedItemID, try XCTUnwrap(viewModel.filteredItems[safe: 1]?.id))
    }

    func testSearchResetsSelectionToFirstMatchingItem() throws {
        let store = ClipboardHistoryStore(items: [
            ClipboardItem.make(content: "git status", createdAt: Date(timeIntervalSince1970: 1)),
            ClipboardItem.make(content: "swift build", createdAt: Date(timeIntervalSince1970: 2)),
            ClipboardItem.make(content: "swift test", createdAt: Date(timeIntervalSince1970: 3)),
        ])
        let viewModel = AppViewModel(
            store: store,
            shortcutLabel: "⌘⇧V",
            onCopy: { _ in },
            onTogglePinned: { _ in },
            onDelete: { _ in },
            onClearAll: {}
        )

        viewModel.moveSelection(delta: 1)
        viewModel.searchText = "git"

        XCTAssertEqual(viewModel.selectedItemID, try XCTUnwrap(viewModel.filteredItems.first?.id))
    }

    func testActivateSelectionCopiesSelectedItem() {
        let store = ClipboardHistoryStore(items: [
            ClipboardItem.make(content: "git status", createdAt: Date(timeIntervalSince1970: 1)),
            ClipboardItem.make(content: "swift build", createdAt: Date(timeIntervalSince1970: 2)),
        ])
        var activatedContent: String?
        let viewModel = AppViewModel(
            store: store,
            shortcutLabel: "⌘⇧V",
            onCopy: { _ in },
            onActivate: { activatedContent = $0.content },
            onTogglePinned: { _ in },
            onDelete: { _ in },
            onClearAll: {}
        )

        viewModel.activateSelectedItem()

        XCTAssertEqual(activatedContent, "swift build")
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else {
            return nil
        }

        return self[index]
    }
}

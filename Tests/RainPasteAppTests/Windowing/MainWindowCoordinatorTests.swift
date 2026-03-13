import XCTest
@testable import RainPasteApp

@MainActor
final class MainWindowCoordinatorTests: XCTestCase {
    func testShowUsesNonActivatingPresentation() {
        let window = FakeCommandPanelWindow()
        let coordinator = MainWindowCoordinator(windowFactory: { _ in window })
        let viewModel = makeViewModel()

        coordinator.show(viewModel: viewModel)

        XCTAssertEqual(window.showWithoutActivatingCount, 1)
    }

    func testEnterKeyTriggersSelectedItemActivation() {
        let window = FakeCommandPanelWindow()
        var activatedContent: String?
        let coordinator = MainWindowCoordinator(windowFactory: { _ in window })
        let viewModel = makeViewModel(onActivate: { activatedContent = $0.content })

        coordinator.show(viewModel: viewModel)
        let handled = window.keyCodeHandler?(36)

        XCTAssertEqual(handled, true)
        XCTAssertEqual(activatedContent, "swift build")
    }

    private func makeViewModel(
        onActivate: @escaping (ClipboardItem) -> Void = { _ in }
    ) -> AppViewModel {
        let store = ClipboardHistoryStore(items: [
            ClipboardItem.make(content: "git status", createdAt: Date(timeIntervalSince1970: 1)),
            ClipboardItem.make(content: "swift build", createdAt: Date(timeIntervalSince1970: 2)),
        ])

        return AppViewModel(
            store: store,
            shortcutLabel: "⌘⇧V",
            onCopy: { _ in },
            onActivate: onActivate,
            onTogglePinned: { _ in },
            onDelete: { _ in },
            onClearAll: {}
        )
    }
}

@MainActor
private final class FakeCommandPanelWindow: CommandPanelWindowing {
    var keyCodeHandler: ((UInt16) -> Bool)?
    private(set) var showWithoutActivatingCount = 0
    private(set) var closeCount = 0

    func showWithoutActivating() {
        showWithoutActivatingCount += 1
    }

    func closePanel() {
        closeCount += 1
    }
}

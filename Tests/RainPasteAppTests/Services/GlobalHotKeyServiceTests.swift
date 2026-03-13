import AppKit
import Carbon.HIToolbox
import XCTest
@testable import RainPasteApp

final class GlobalHotKeyServiceTests: XCTestCase {
    func testDefaultShortcutFormatsForDisplay() {
        let shortcut = GlobalShortcut.defaultValue

        XCTAssertEqual(shortcut.displayLabel, "⌘⇧V")
    }
}

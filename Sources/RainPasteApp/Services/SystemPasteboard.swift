import AppKit

protocol SystemPasteboard: AnyObject {
    var changeCount: Int { get }

    func currentText() -> String?
    func write(text: String)
}

final class GeneralPasteboardClient: SystemPasteboard {
    private let pasteboard: NSPasteboard

    init(pasteboard: NSPasteboard = .general) {
        self.pasteboard = pasteboard
    }

    var changeCount: Int {
        pasteboard.changeCount
    }

    func currentText() -> String? {
        pasteboard.string(forType: .string)
    }

    func write(text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

import Foundation

@MainActor
final class ClipboardMonitoring {
    private let pasteboard: SystemPasteboard
    private let store: ClipboardHistoryStore
    private var timer: Timer?
    private var lastChangeCount: Int?

    init(
        pasteboard: SystemPasteboard = GeneralPasteboardClient(),
        store: ClipboardHistoryStore
    ) {
        self.pasteboard = pasteboard
        self.store = store
    }

    func start(interval: TimeInterval = 0.75) {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.poll()
            }
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func poll() {
        let currentChangeCount = pasteboard.changeCount
        guard lastChangeCount != currentChangeCount else {
            return
        }

        lastChangeCount = currentChangeCount
        guard let text = pasteboard.currentText() else {
            return
        }

        store.ingest(text)
    }

    func write(_ text: String) {
        pasteboard.write(text: text)
        lastChangeCount = pasteboard.changeCount
    }
}

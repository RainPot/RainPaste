import Combine
import Foundation

@MainActor
final class ClipboardHistoryStore: ObservableObject {
    @Published private(set) var items: [ClipboardItem]
    @Published private(set) var settings: AppSettings

    init(
        items: [ClipboardItem] = [],
        settings: AppSettings = .defaultValue
    ) {
        self.items = ClipboardItem.sortForDisplay(items)
        self.settings = settings
    }

    func ingest(_ text: String, at date: Date = .now) {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            return
        }

        if settings.ignoresConsecutiveDuplicates, items.first?.content == normalized {
            return
        }

        items.insert(
            ClipboardItem(
                id: UUID(),
                content: normalized,
                createdAt: date,
                isPinned: false
            ),
            at: 0
        )
        items = ClipboardItem.sortForDisplay(items)
        trimIfNeeded()
    }

    func setPinned(_ id: UUID, isPinned: Bool) {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return
        }

        items[index].isPinned = isPinned
        items = ClipboardItem.sortForDisplay(items)
    }

    func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
    }

    func clearAll() {
        items.removeAll()
    }

    func restore(snapshot: PersistedSnapshot) {
        settings = snapshot.settings
        items = ClipboardItem.sortForDisplay(snapshot.items)
        trimIfNeeded()
    }

    func updateSettings(_ settings: AppSettings) {
        self.settings = settings
        trimIfNeeded()
    }

    func snapshot() -> PersistedSnapshot {
        PersistedSnapshot(items: items, settings: settings)
    }

    private func trimIfNeeded() {
        while items.count > settings.maxHistoryCount {
            if let lastUnpinnedIndex = items.lastIndex(where: { !$0.isPinned }) {
                items.remove(at: lastUnpinnedIndex)
            } else {
                items.removeLast()
            }
        }
    }
}

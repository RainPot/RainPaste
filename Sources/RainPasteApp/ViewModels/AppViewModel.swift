import Combine
import Foundation

@MainActor
final class AppViewModel: ObservableObject {
    @Published var searchText = ""
    @Published private(set) var selectedItemID: UUID?
    @Published private(set) var isMonitoringPaused = false

    let shortcutLabel: String

    private let store: ClipboardHistoryStore
    private let onCopy: (ClipboardItem) -> Void
    private let onActivate: (ClipboardItem) -> Void
    private let onTogglePinned: (ClipboardItem) -> Void
    private let onDelete: (ClipboardItem) -> Void
    private let onClearAll: () -> Void
    private let onToggleMonitoring: () -> Void
    private let onClose: () -> Void
    private var cancellables: Set<AnyCancellable> = []

    init(
        store: ClipboardHistoryStore,
        shortcutLabel: String,
        onCopy: @escaping (ClipboardItem) -> Void,
        onActivate: @escaping (ClipboardItem) -> Void = { _ in },
        onTogglePinned: @escaping (ClipboardItem) -> Void,
        onDelete: @escaping (ClipboardItem) -> Void,
        onClearAll: @escaping () -> Void,
        onToggleMonitoring: @escaping () -> Void = {},
        onClose: @escaping () -> Void = {}
    ) {
        self.store = store
        self.shortcutLabel = shortcutLabel
        self.onCopy = onCopy
        self.onActivate = onActivate
        self.onTogglePinned = onTogglePinned
        self.onDelete = onDelete
        self.onClearAll = onClearAll
        self.onToggleMonitoring = onToggleMonitoring
        self.onClose = onClose

        store.$items
            .sink { [weak self] _ in
                self?.syncSelection()
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        $searchText
            .dropFirst()
            .sink { [weak self] query in
                self?.syncSelection(resetToFirst: true, query: query)
            }
            .store(in: &cancellables)

        syncSelection(resetToFirst: true)
    }

    var filteredItems: [ClipboardItem] {
        filteredItems(matching: searchText)
    }

    var totalCount: Int {
        store.items.count
    }

    var settings: AppSettings {
        store.settings
    }

    var selectedItem: ClipboardItem? {
        filteredItems.first { $0.id == selectedItemID }
    }

    func copy(_ item: ClipboardItem) {
        onCopy(item)
    }

    func togglePinned(_ item: ClipboardItem) {
        onTogglePinned(item)
    }

    func delete(_ item: ClipboardItem) {
        onDelete(item)
    }

    func clearAll() {
        onClearAll()
    }

    func toggleMonitoring() {
        onToggleMonitoring()
    }

    func closePanel() {
        onClose()
    }

    func prepareForPresentation() {
        syncSelection(resetToFirst: true)
    }

    func select(_ item: ClipboardItem) {
        guard filteredItems.contains(where: { $0.id == item.id }) else {
            return
        }

        selectedItemID = item.id
    }

    func moveSelection(delta: Int) {
        let items = filteredItems
        guard !items.isEmpty else {
            selectedItemID = nil
            return
        }

        guard let selectedItemID,
              let currentIndex = items.firstIndex(where: { $0.id == selectedItemID })
        else {
            self.selectedItemID = items.first?.id
            return
        }

        let nextIndex = min(max(currentIndex + delta, 0), items.count - 1)
        self.selectedItemID = items[nextIndex].id
    }

    func activateSelectedItem() {
        guard let item = selectedItem ?? filteredItems.first else {
            return
        }

        selectedItemID = item.id
        onActivate(item)
    }

    func updateMaxHistoryCount(_ value: Int) {
        var updated = store.settings
        updated.maxHistoryCount = max(10, value)
        store.updateSettings(updated)
    }

    func setIgnoreDuplicates(_ enabled: Bool) {
        var updated = store.settings
        updated.ignoresConsecutiveDuplicates = enabled
        store.updateSettings(updated)
    }

    func setCloseWindowAfterCopy(_ enabled: Bool) {
        var updated = store.settings
        updated.closesWindowAfterCopy = enabled
        store.updateSettings(updated)
    }

    func setMonitoringPaused(_ paused: Bool) {
        isMonitoringPaused = paused
    }

    private func syncSelection(resetToFirst: Bool = false, query: String? = nil) {
        let items = filteredItems(matching: query ?? searchText)
        guard !items.isEmpty else {
            selectedItemID = nil
            return
        }

        if resetToFirst {
            selectedItemID = items.first?.id
            return
        }

        if let selectedItemID,
           items.contains(where: { $0.id == selectedItemID }) {
            return
        }

        selectedItemID = items.first?.id
    }

    private func filteredItems(matching query: String) -> [ClipboardItem] {
        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedQuery.isEmpty else {
            return store.items
        }

        return store.items.filter { item in
            item.content.localizedCaseInsensitiveContains(normalizedQuery)
        }
    }
}

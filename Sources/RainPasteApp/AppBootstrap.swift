import AppKit
import Combine
import Foundation

@MainActor
final class AppBootstrap {
    let store: ClipboardHistoryStore

    private let persistence: HistoryPersistence
    private let monitor: ClipboardMonitoring
    private let autoPasteService: AutoPasteService
    private let hotKeyService: GlobalHotKeyService
    private let menuBarController: MenuBarController
    private let windowCoordinator: MainWindowCoordinator
    private let shortcut: GlobalShortcut
    private var cancellables: Set<AnyCancellable> = []
    private(set) var isMonitoringPaused = false

    lazy var viewModel: AppViewModel = {
        AppViewModel(
            store: store,
            shortcutLabel: shortcut.displayLabel,
            onCopy: { [weak self] item in
                self?.copy(item)
            },
            onActivate: { [weak self] item in
                self?.paste(item)
            },
            onTogglePinned: { [weak self] item in
                self?.togglePinned(item)
            },
            onDelete: { [weak self] item in
                self?.delete(item)
            },
            onClearAll: { [weak self] in
                self?.clearAll()
            },
            onToggleMonitoring: { [weak self] in
                self?.toggleMonitoring()
            },
            onClose: { [weak self] in
                self?.closeMainWindow()
            }
        )
    }()

    init(
        persistence: HistoryPersistence? = nil,
        pasteboard: SystemPasteboard = GeneralPasteboardClient(),
        autoPasteService: AutoPasteService = AutoPasteService(),
        hotKeyService: GlobalHotKeyService = GlobalHotKeyService(),
        shortcut: GlobalShortcut = .defaultValue
    ) {
        self.store = ClipboardHistoryStore(settings: .defaultValue)
        self.persistence = persistence ?? HistoryPersistence(fileURL: Self.defaultStorageURL())
        self.monitor = ClipboardMonitoring(pasteboard: pasteboard, store: store)
        self.autoPasteService = autoPasteService
        self.hotKeyService = hotKeyService
        self.menuBarController = MenuBarController()
        self.windowCoordinator = MainWindowCoordinator()
        self.shortcut = shortcut

        bindStore()
    }

    func start() {
        loadSnapshot()
        viewModel.setMonitoringPaused(isMonitoringPaused)
        menuBarController.configure(
            actions: MenuBarActions(
                onOpenMainWindow: { [weak self] in
                    self?.showMainWindow()
                },
                onSelectHistoryItem: { [weak self] itemID in
                    self?.copyHistoryItem(id: itemID)
                },
                onToggleMonitoring: { [weak self] in
                    self?.toggleMonitoring()
                },
                onClearHistory: { [weak self] in
                    self?.clearAll()
                },
                onQuit: {
                    NSApp.terminate(nil)
                }
            )
        )
        refreshMenu()
        monitor.start()
        _ = hotKeyService.register(shortcut) { [weak self] in
            Task { @MainActor [weak self] in
                self?.showMainWindow()
            }
        }
    }

    func stop() {
        monitor.stop()
        hotKeyService.unregister()
    }

    func showMainWindow() {
        autoPasteService.captureCurrentTarget(
            excludingBundleIdentifier: Bundle.main.bundleIdentifier
        )
        viewModel.prepareForPresentation()
        windowCoordinator.show(viewModel: viewModel)
    }

    func closeMainWindow() {
        windowCoordinator.close()
    }

    private func bindStore() {
        Publishers.CombineLatest(store.$items, store.$settings)
            .dropFirst()
            .sink { [weak self] items, settings in
                guard let self else {
                    return
                }

                do {
                    try persistence.save(items: items, settings: settings)
                } catch {
                    fputs("保存历史失败: \(error)\n", stderr)
                }

                refreshMenu()
            }
            .store(in: &cancellables)
    }

    private func loadSnapshot() {
        do {
            let snapshot = try persistence.load()
            store.restore(snapshot: snapshot)
        } catch {
            fputs("读取历史失败，已回退为空状态: \(error)\n", stderr)
            store.restore(snapshot: PersistedSnapshot(items: [], settings: .defaultValue))
        }
    }

    private func copyHistoryItem(id: UUID) {
        guard let item = store.items.first(where: { $0.id == id }) else {
            return
        }
        copy(item)
    }

    private func copy(_ item: ClipboardItem) {
        monitor.write(item.content)
        store.ingest(item.content)
        if store.settings.closesWindowAfterCopy {
            windowCoordinator.close()
        }
    }

    private func paste(_ item: ClipboardItem) {
        monitor.write(item.content)
        store.ingest(item.content)
        windowCoordinator.close()
        _ = autoPasteService.pasteIntoCapturedTarget()
    }

    private func togglePinned(_ item: ClipboardItem) {
        store.setPinned(item.id, isPinned: !item.isPinned)
    }

    private func delete(_ item: ClipboardItem) {
        store.delete(item.id)
    }

    private func clearAll() {
        store.clearAll()
    }

    private func toggleMonitoring() {
        isMonitoringPaused.toggle()
        viewModel.setMonitoringPaused(isMonitoringPaused)
        if isMonitoringPaused {
            monitor.stop()
        } else {
            monitor.start()
        }
        refreshMenu()
    }

    private func refreshMenu() {
        menuBarController.refresh(items: store.items, isMonitoringPaused: isMonitoringPaused)
    }

    private static func defaultStorageURL() -> URL {
        let rootURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory

        return rootURL
            .appendingPathComponent("RainPaste", isDirectory: true)
            .appendingPathComponent("history.json")
    }
}

import AppKit

struct MenuBarActions {
    let onOpenMainWindow: () -> Void
    let onSelectHistoryItem: (UUID) -> Void
    let onToggleMonitoring: () -> Void
    let onClearHistory: () -> Void
    let onQuit: () -> Void
}

@MainActor
final class MenuBarController: NSObject {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private var actions: MenuBarActions?

    func configure(actions: MenuBarActions) {
        self.actions = actions
        guard let button = statusItem.button else {
            return
        }

        button.image = NSImage(
            systemSymbolName: "menubar.dock.rectangle",
            accessibilityDescription: "RainPaste"
        )
        button.contentTintColor = NSColor(
            calibratedRed: 0.68,
            green: 1.0,
            blue: 0.86,
            alpha: 1
        )
        button.appearsDisabled = false
    }

    func refresh(items: [ClipboardItem], isMonitoringPaused: Bool) {
        let state = MenuBarState(items: items, isMonitoringPaused: isMonitoringPaused)
        let entries = MenuBarContentBuilder.entries(from: state)
        let menu = NSMenu()

        for entry in entries {
            switch entry {
            case .separator:
                menu.addItem(.separator())
            case let .header(title):
                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
            case let .placeholder(title):
                let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
                item.isEnabled = false
                menu.addItem(item)
            case let .history(id, title):
                let item = NSMenuItem(title: title, action: #selector(selectHistoryItem(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = id
                menu.addItem(item)
            case let .action(type, title):
                let item = NSMenuItem(title: title, action: selector(for: type), keyEquivalent: "")
                item.target = self
                menu.addItem(item)
            }
        }

        statusItem.menu = menu
    }

    @objc private func openMainWindow() {
        actions?.onOpenMainWindow()
    }

    @objc private func selectHistoryItem(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID else {
            return
        }
        actions?.onSelectHistoryItem(id)
    }

    @objc private func toggleMonitoring() {
        actions?.onToggleMonitoring()
    }

    @objc private func clearHistory() {
        actions?.onClearHistory()
    }

    @objc private func quitApp() {
        actions?.onQuit()
    }

    private func selector(for type: MenuBarActionType) -> Selector {
        switch type {
        case .openMainWindow:
            return #selector(openMainWindow)
        case .toggleMonitoring:
            return #selector(toggleMonitoring)
        case .clearHistory:
            return #selector(clearHistory)
        case .quit:
            return #selector(quitApp)
        }
    }
}

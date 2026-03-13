import Foundation

struct MenuBarState {
    let items: [ClipboardItem]
    let isMonitoringPaused: Bool
}

enum MenuBarEntry {
    case header(String)
    case history(id: UUID, title: String)
    case placeholder(String)
    case separator
    case action(MenuBarActionType, title: String)
}

enum MenuBarActionType {
    case openMainWindow
    case toggleMonitoring
    case clearHistory
    case quit
}

enum MenuBarContentBuilder {
    static func entries(from state: MenuBarState) -> [MenuBarEntry] {
        var entries: [MenuBarEntry] = [
            .header("RainPaste"),
            .separator,
        ]

        if state.items.isEmpty {
            entries.append(.placeholder("暂无文本历史"))
        } else {
            entries.append(contentsOf: state.items.prefix(8).map { item in
                .history(id: item.id, title: title(for: item))
            })
        }

        entries.append(contentsOf: [
            .separator,
            .action(.openMainWindow, title: "打开主窗口"),
            .action(.toggleMonitoring, title: state.isMonitoringPaused ? "恢复监听" : "暂停监听"),
            .action(.clearHistory, title: "清空历史"),
            .separator,
            .action(.quit, title: "退出"),
        ])

        return entries
    }

    private static func title(for item: ClipboardItem) -> String {
        let content = item.content
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let short = String(content.prefix(64))
        return item.isPinned ? "[置顶] \(short)" : short
    }
}

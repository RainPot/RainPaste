import Foundation

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let createdAt: Date
    var isPinned: Bool

    static func sortForDisplay(_ items: [ClipboardItem]) -> [ClipboardItem] {
        items.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }

            return lhs.createdAt > rhs.createdAt
        }
    }

    static func make(
        content: String,
        createdAt: Date = .now,
        isPinned: Bool = false
    ) -> ClipboardItem {
        ClipboardItem(
            id: UUID(),
            content: content,
            createdAt: createdAt,
            isPinned: isPinned
        )
    }
}

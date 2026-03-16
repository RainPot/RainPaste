import Foundation

struct AppSettings: Codable, Equatable {
    var maxHistoryCount: Int
    var ignoresConsecutiveDuplicates: Bool
    var closesWindowAfterCopy: Bool

    static let defaultValue = AppSettings(
        maxHistoryCount: 2000,
        ignoresConsecutiveDuplicates: true,
        closesWindowAfterCopy: true
    )
}

import Foundation

struct AppSettings: Codable, Equatable {
    var maxHistoryCount: Int
    var ignoresConsecutiveDuplicates: Bool
    var closesWindowAfterCopy: Bool

    static let defaultValue = AppSettings(
        maxHistoryCount: 200,
        ignoresConsecutiveDuplicates: true,
        closesWindowAfterCopy: true
    )
}

import Foundation

struct PersistedSnapshot: Codable, Equatable {
    let items: [ClipboardItem]
    let settings: AppSettings
}

struct HistoryPersistence {
    let fileURL: URL

    func load() throws -> PersistedSnapshot {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return PersistedSnapshot(items: [], settings: .defaultValue)
        }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(PersistedSnapshot.self, from: data)
    }

    func save(items: [ClipboardItem], settings: AppSettings) throws {
        let snapshot = PersistedSnapshot(items: items, settings: settings)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let directoryURL = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        let data = try encoder.encode(snapshot)
        try data.write(to: fileURL, options: .atomic)
    }
}

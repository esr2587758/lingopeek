import Foundation

public final class PhraseStore: @unchecked Sendable {
    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let lock = NSLock()

    public init(fileURL: URL) {
        self.fileURL = fileURL
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    public static func defaultStore() -> PhraseStore {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = base.appending(path: "LingoPeek", directoryHint: .isDirectory)
        return PhraseStore(fileURL: directory.appending(path: "phrases.json"))
    }

    public func load() throws -> [SavedPhrase] {
        lock.lock()
        defer { lock.unlock() }

        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }
        let data = try Data(contentsOf: fileURL)
        return try decoder.decode([SavedPhrase].self, from: data)
    }

    public func save(_ phrases: [SavedPhrase]) throws {
        lock.lock()
        defer { lock.unlock() }

        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(phrases)
        try data.write(to: fileURL, options: [.atomic])
    }
}

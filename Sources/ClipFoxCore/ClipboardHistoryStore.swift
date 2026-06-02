import Foundation

public final class ClipboardHistoryStore: @unchecked Sendable {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(fileURL: URL) {
        self.fileURL = fileURL
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    public static func defaultStore(appName: String = "ClipFox") throws -> ClipboardHistoryStore {
        let baseURL = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let appURL = baseURL.appendingPathComponent(appName, isDirectory: true)
        try FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true)
        return ClipboardHistoryStore(fileURL: appURL.appendingPathComponent("history.json"))
    }

    public func load(maxItems: Int = 200) throws -> ClipboardHistory {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return ClipboardHistory(maxItems: maxItems)
        }

        let data = try Data(contentsOf: fileURL)
        var history = try decoder.decode(ClipboardHistory.self, from: data)
        history.maxItems = maxItems
        return history
    }

    public func save(_ history: ClipboardHistory) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let data = try encoder.encode(history)
        try data.write(to: fileURL, options: [.atomic])
    }
}

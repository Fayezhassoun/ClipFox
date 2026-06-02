import Foundation

public struct ClipboardItem: Codable, Identifiable, Equatable, Sendable {
    public let id: UUID
    public var text: String
    public var createdAt: Date
    public var lastCopiedAt: Date
    public var isPinned: Bool
    public var copyCount: Int

    public init(
        id: UUID = UUID(),
        text: String,
        createdAt: Date = Date(),
        lastCopiedAt: Date = Date(),
        isPinned: Bool = false,
        copyCount: Int = 1
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.lastCopiedAt = lastCopiedAt
        self.isPinned = isPinned
        self.copyCount = copyCount
    }

    public var title: String {
        let normalized = text
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\t", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if normalized.isEmpty {
            return "Empty text"
        }

        if normalized.count > 140 {
            return String(normalized.prefix(140)) + "..."
        }

        return normalized
    }
}

import Foundation

public struct ClipboardHistory: Codable, Equatable, Sendable {
    public private(set) var items: [ClipboardItem]
    public var maxItems: Int

    public init(items: [ClipboardItem] = [], maxItems: Int = 200) {
        self.items = items
        self.maxItems = max(1, maxItems)
        trimToLimit()
    }

    @discardableResult
    public mutating func record(_ text: String, now: Date = Date()) -> ClipboardItem? {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanText.isEmpty else {
            return nil
        }

        if let existingIndex = items.firstIndex(where: { $0.text == cleanText }) {
            var existing = items.remove(at: existingIndex)
            existing.lastCopiedAt = now
            existing.copyCount += 1
            items.insert(existing, at: insertionIndex(forPinned: existing.isPinned))
            return existing
        }

        let item = ClipboardItem(text: cleanText, createdAt: now, lastCopiedAt: now)
        items.insert(item, at: insertionIndex(forPinned: false))
        trimToLimit()
        return item
    }

    public mutating func togglePin(id: ClipboardItem.ID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else {
            return
        }

        var item = items.remove(at: index)
        item.isPinned.toggle()
        items.insert(item, at: insertionIndex(forPinned: item.isPinned))
    }

    public mutating func delete(id: ClipboardItem.ID) {
        items.removeAll { $0.id == id }
    }

    public mutating func clearUnpinned() {
        items.removeAll { !$0.isPinned }
    }

    public mutating func merge(_ remoteItems: [ClipboardItem]) {
        var mergedByText: [String: ClipboardItem] = [:]

        for item in items + remoteItems {
            if let existing = mergedByText[item.text] {
                mergedByText[item.text] = merge(existing, item)
            } else {
                mergedByText[item.text] = item
            }
        }

        items = mergedByText.values.sorted { left, right in
            if left.isPinned != right.isPinned {
                return left.isPinned
            }

            return left.lastCopiedAt > right.lastCopiedAt
        }

        trimToLimit()
    }

    public func search(_ query: String) -> [ClipboardItem] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else {
            return items
        }

        return items.filter {
            $0.text.localizedCaseInsensitiveContains(cleanQuery)
        }
    }

    private func insertionIndex(forPinned isPinned: Bool) -> Int {
        if isPinned {
            return 0
        }

        return items.firstIndex { !$0.isPinned } ?? items.endIndex
    }

    private mutating func trimToLimit() {
        let pinned = items.filter(\.isPinned)
        var unpinned = items.filter { !$0.isPinned }
        let allowedUnpinnedCount = max(0, maxItems - pinned.count)

        if unpinned.count > allowedUnpinnedCount {
            unpinned = Array(unpinned.prefix(allowedUnpinnedCount))
        }

        items = pinned + unpinned
    }

    private func merge(_ left: ClipboardItem, _ right: ClipboardItem) -> ClipboardItem {
        ClipboardItem(
            id: left.createdAt <= right.createdAt ? left.id : right.id,
            text: left.text,
            createdAt: min(left.createdAt, right.createdAt),
            lastCopiedAt: max(left.lastCopiedAt, right.lastCopiedAt),
            isPinned: left.isPinned || right.isPinned,
            copyCount: max(left.copyCount, right.copyCount)
        )
    }
}

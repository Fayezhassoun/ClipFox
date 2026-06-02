import ClipFoxCore
import Foundation

enum CheckFailure: Error, CustomStringConvertible {
    case failed(String)

    var description: String {
        switch self {
        case .failed(let message):
            return message
        }
    }
}

func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
    if !condition() {
        throw CheckFailure.failed(message)
    }
}

func recordIgnoresEmptyText() throws {
    var history = ClipboardHistory()

    try expect(history.record("   \n\t ") == nil, "empty text should not be recorded")
    try expect(history.items.isEmpty, "history should remain empty")
}

func recordDeduplicatesAndMovesExistingItemToTop() throws {
    var history = ClipboardHistory()
    let first = history.record("first")!
    _ = history.record("second")

    let updated = history.record("first")!

    try expect(updated.id == first.id, "deduplicated item should keep its id")
    try expect(updated.copyCount == 2, "deduplicated item should increment copy count")
    try expect(history.items.map(\.text) == ["first", "second"], "deduplicated item should move to top")
}

func pinnedItemsStayAboveUnpinnedItems() throws {
    var history = ClipboardHistory()
    let first = history.record("first")!
    _ = history.record("second")

    history.togglePin(id: first.id)
    _ = history.record("third")

    try expect(history.items.map(\.text) == ["first", "third", "second"], "pinned item should stay first")
    try expect(history.items[0].isPinned, "first item should be pinned")
}

func trimKeepsPinnedItemsAndNewestUnpinnedItems() throws {
    var history = ClipboardHistory(maxItems: 3)
    let keepPinned = history.record("pinned")!
    history.togglePin(id: keepPinned.id)
    _ = history.record("one")
    _ = history.record("two")
    _ = history.record("three")

    try expect(history.items.map(\.text) == ["pinned", "three", "two"], "trim should keep pinned and newest unpinned items")
}

func searchIsCaseInsensitive() throws {
    var history = ClipboardHistory()
    _ = history.record("Alpha Project")
    _ = history.record("beta")

    try expect(history.search("alpha").map(\.text) == ["Alpha Project"], "search should be case insensitive")
}

func mergeCombinesLocalAndRemoteItems() throws {
    let now = Date()
    var history = ClipboardHistory(items: [
        ClipboardItem(text: "local", createdAt: now, lastCopiedAt: now),
        ClipboardItem(text: "shared", createdAt: now, lastCopiedAt: now, isPinned: false, copyCount: 1)
    ])

    history.merge([
        ClipboardItem(text: "remote", createdAt: now.addingTimeInterval(1), lastCopiedAt: now.addingTimeInterval(1)),
        ClipboardItem(text: "shared", createdAt: now.addingTimeInterval(-1), lastCopiedAt: now.addingTimeInterval(5), isPinned: true, copyCount: 3)
    ])

    try expect(history.items.map(\.text) == ["shared", "remote", "local"], "merge should sort pinned first, then newest")
    try expect(history.items[0].isPinned, "merge should preserve pinned state")
    try expect(history.items[0].copyCount == 3, "merge should keep highest copy count")
}

let checks: [(String, () throws -> Void)] = [
    ("recordIgnoresEmptyText", recordIgnoresEmptyText),
    ("recordDeduplicatesAndMovesExistingItemToTop", recordDeduplicatesAndMovesExistingItemToTop),
    ("pinnedItemsStayAboveUnpinnedItems", pinnedItemsStayAboveUnpinnedItems),
    ("trimKeepsPinnedItemsAndNewestUnpinnedItems", trimKeepsPinnedItemsAndNewestUnpinnedItems),
    ("searchIsCaseInsensitive", searchIsCaseInsensitive),
    ("mergeCombinesLocalAndRemoteItems", mergeCombinesLocalAndRemoteItems)
]

do {
    for (name, check) in checks {
        try check()
        print("PASS \(name)")
    }
    print("All ClipFox core checks passed")
} catch {
    fputs("FAIL \(error)\n", stderr)
    exit(1)
}

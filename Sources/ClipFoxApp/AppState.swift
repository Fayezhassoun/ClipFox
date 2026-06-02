import AppKit
import ClipFoxCore
import Combine

@MainActor
final class AppState: ObservableObject {
    @Published private(set) var history: ClipboardHistory
    @Published var query: String = ""
    @Published var selectedID: ClipboardItem.ID?
    @Published var lastError: String?
    @Published private(set) var cloudStatus: CloudSyncStatus = .checking

    private let store: ClipboardHistoryStore
    private let pasteboard: NSPasteboard
    private let cloudSync: CloudClipboardSyncing
    private let obsidian: ObsidianBridging

    init(
        store: ClipboardHistoryStore,
        pasteboard: NSPasteboard = .general,
        cloudSync: CloudClipboardSyncing = CloudClipboardSync(),
        obsidian: ObsidianBridging = ObsidianBridge()
    ) {
        self.store = store
        self.pasteboard = pasteboard
        self.cloudSync = cloudSync
        self.obsidian = obsidian
        do {
            self.history = try store.load()
        } catch {
            self.history = ClipboardHistory()
            self.lastError = "Could not load clipboard history: \(error.localizedDescription)"
        }

        Task {
            await refreshCloudStatus()
            await syncWithCloud()
        }
    }

    var visibleItems: [ClipboardItem] {
        history.search(query)
    }

    func record(_ text: String) {
        guard history.record(text) != nil else {
            return
        }
        save()
        scheduleCloudSync()
    }

    func copy(_ item: ClipboardItem, pasteAfterCopy: Bool = true) {
        pasteboard.clearContents()
        pasteboard.setString(item.text, forType: .string)
        record(item.text)

        if pasteAfterCopy {
            PasteboardPaster.pasteIntoFrontmostApp()
        }
    }

    func togglePin(_ item: ClipboardItem) {
        history.togglePin(id: item.id)
        save()
        scheduleCloudSync()
    }

    func delete(_ item: ClipboardItem) {
        history.delete(id: item.id)
        save()
        scheduleCloudSync()
    }

    func clearUnpinned() {
        history.clearUnpinned()
        save()
        scheduleCloudSync()
    }

    func sendToObsidianInbox(_ item: ClipboardItem) {
        do {
            try obsidian.appendToInbox(item)
            lastError = nil
        } catch ObsidianBridgeError.duplicate {
            lastError = "Already in Obsidian inbox."
        } catch {
            lastError = error.localizedDescription
        }
    }

    func openInObsidianAsNote(_ item: ClipboardItem) {
        do {
            try obsidian.openAsNewNote(item)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }

    func refreshCloudStatus() async {
        cloudStatus = .checking
        cloudStatus = await cloudSync.accountStatus()
    }

    func syncWithCloud() async {
        guard cloudStatus.canSync else {
            return
        }

        cloudStatus = .syncing

        do {
            let remoteItems = try await cloudSync.sync(history: history)
            history.merge(remoteItems)
            save()
            cloudStatus = .available
        } catch {
            cloudStatus = .failed(error.localizedDescription)
        }
    }

    private func save() {
        do {
            try store.save(history)
            lastError = nil
        } catch {
            lastError = "Could not save clipboard history: \(error.localizedDescription)"
        }
    }

    private func scheduleCloudSync() {
        Task {
            await syncWithCloud()
        }
    }
}

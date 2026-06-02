import AppKit
import ClipFoxCore

@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let state: AppState
    private let windowController: HistoryWindowController
    private let menu = NSMenu()

    private static let maxItemsInMenu = 30
    private static let titlePreviewLength = 60

    init(state: AppState, windowController: HistoryWindowController) {
        self.state = state
        self.windowController = windowController
        super.init()
        configure()
    }

    private func configure() {
        statusItem.button?.image = NSImage(systemSymbolName: "paperclip", accessibilityDescription: "ClipFox")
        menu.delegate = self
        menu.autoenablesItems = false
        statusItem.menu = menu
    }

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        let items = state.history.items
        let pinned = items.filter(\.isPinned)
        let recent = items.filter { !$0.isPinned }.prefix(Self.maxItemsInMenu)

        if items.isEmpty {
            let empty = NSMenuItem(title: "Clipboard is empty", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        } else {
            if !pinned.isEmpty {
                menu.addItem(sectionHeader("Pinned"))
                for clip in pinned {
                    menu.addItem(clipItem(clip))
                }
                menu.addItem(NSMenuItem.separator())
            }

            menu.addItem(sectionHeader("Recent"))
            for clip in recent {
                menu.addItem(clipItem(clip))
            }
        }

        menu.addItem(NSMenuItem.separator())

        let search = NSMenuItem(title: "Search…", action: #selector(showHistory), keyEquivalent: "f")
        search.target = self
        menu.addItem(search)

        let clear = NSMenuItem(title: "Clear Unpinned", action: #selector(clearUnpinned), keyEquivalent: "")
        clear.target = self
        clear.isEnabled = !items.allSatisfy(\.isPinned) && !items.isEmpty
        menu.addItem(clear)

        if LaunchAtLogin.isAvailable {
            let launch = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
            launch.target = self
            launch.state = LaunchAtLogin.isEnabled ? .on : .off
            menu.addItem(launch)
        }

        menu.addItem(NSMenuItem.separator())

        let privacyNote = NSMenuItem(title: "Skipping concealed clips from password managers", action: nil, keyEquivalent: "")
        privacyNote.isEnabled = false
        privacyNote.attributedTitle = NSAttributedString(
            string: "Skipping concealed clips from password managers",
            attributes: [
                .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
                .foregroundColor: NSColor.tertiaryLabelColor
            ]
        )
        menu.addItem(privacyNote)

        menu.addItem(NSMenuItem.separator())

        let quit = NSMenuItem(title: "Quit ClipFox", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quit)
    }

    private func clipItem(_ clip: ClipboardItem) -> NSMenuItem {
        let prefix = clip.isPinned ? "📌  " : ""
        let title = prefix + previewTitle(for: clip)
        let item = NSMenuItem(title: title, action: #selector(pasteClip(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = clip.id
        item.toolTip = clip.text
        return item
    }

    private func previewTitle(for clip: ClipboardItem) -> String {
        let collapsed = clip.title
            .split(whereSeparator: \.isNewline)
            .joined(separator: " ⏎ ")
        if collapsed.count <= Self.titlePreviewLength {
            return collapsed
        }
        return String(collapsed.prefix(Self.titlePreviewLength)) + "…"
    }

    private func sectionHeader(_ title: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        item.attributedTitle = NSAttributedString(
            string: title,
            attributes: [
                .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        )
        return item
    }

    @objc private func pasteClip(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? ClipboardItem.ID,
              let clip = state.history.items.first(where: { $0.id == id }) else {
            return
        }
        state.copy(clip)
    }

    @objc private func showHistory() {
        windowController.toggle()
    }

    @objc private func clearUnpinned() {
        state.clearUnpinned()
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            try LaunchAtLogin.setEnabled(!LaunchAtLogin.isEnabled)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Could not change Launch at Login"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }
}

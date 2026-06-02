import AppKit

@MainActor
final class StatusBarController {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let windowController: HistoryWindowController

    init(windowController: HistoryWindowController) {
        self.windowController = windowController
        configure()
    }

    private func configure() {
        statusItem.button?.image = NSImage(systemSymbolName: "paperclip", accessibilityDescription: "ClipFox")
        statusItem.button?.target = self
        statusItem.button?.action = #selector(toggleHistory)

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Show History", action: #selector(toggleHistory), keyEquivalent: "h"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit ClipFox", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        menu.items.forEach { $0.target = self }
        statusItem.menu = menu
    }

    @objc private func toggleHistory() {
        windowController.toggle()
    }
}

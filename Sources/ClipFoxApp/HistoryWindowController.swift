import AppKit
import SwiftUI

@MainActor
final class HistoryWindowController {
    private let state: AppState
    private var window: NSWindow?

    init(state: AppState) {
        self.state = state
    }

    func toggle() {
        if let window, window.isVisible {
            window.orderOut(nil)
        } else {
            show()
        }
    }

    func show() {
        if window == nil {
            let rootView = HistoryView(state: state) { [weak self] in
                self?.window?.orderOut(nil)
            }

            let hostingController = NSHostingController(rootView: rootView)
            let newWindow = NSWindow(contentViewController: hostingController)
            newWindow.title = "ClipFox"
            newWindow.styleMask = [.titled, .closable, .resizable, .fullSizeContentView]
            newWindow.titlebarAppearsTransparent = true
            newWindow.isMovableByWindowBackground = true
            newWindow.level = .floating
            newWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window = newWindow
        }

        guard let window else {
            return
        }

        position(window)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func position(_ window: NSWindow) {
        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let frame = screen?.visibleFrame else {
            return
        }

        let size = window.frame.size == .zero ? NSSize(width: 560, height: 560) : window.frame.size
        let origin = NSPoint(
            x: frame.midX - size.width / 2,
            y: frame.maxY - size.height - 80
        )
        window.setFrame(NSRect(origin: origin, size: size), display: true)
    }
}

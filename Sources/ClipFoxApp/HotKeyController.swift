import AppKit

@MainActor
final class HotKeyController {
    private let windowController: HistoryWindowController
    private var monitor: Any?

    init(windowController: HistoryWindowController) {
        self.windowController = windowController
    }

    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.modifierFlags.contains([.command, .shift]),
                  event.charactersIgnoringModifiers?.lowercased() == "c" else {
                return
            }

            Task { @MainActor in
                self?.windowController.toggle()
            }
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
        }
        monitor = nil
    }
}

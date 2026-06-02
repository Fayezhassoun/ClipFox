import AppKit
import ClipFoxCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var state: AppState?
    private var monitor: ClipboardMonitor?
    private var statusBar: StatusBarController?
    private var windowController: HistoryWindowController?
    private var hotKeyController: HotKeyController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        do {
            let store = try ClipboardHistoryStore.defaultStore()
            let state = AppState(store: store)
            let windowController = HistoryWindowController(state: state)

            self.state = state
            self.windowController = windowController
            self.statusBar = StatusBarController(state: state, windowController: windowController)

            let monitor = ClipboardMonitor(state: state)
            monitor.start()
            self.monitor = monitor

            let hotKeyController = HotKeyController(windowController: windowController)
            hotKeyController.start()
            self.hotKeyController = hotKeyController
        } catch {
            let alert = NSAlert()
            alert.messageText = "ClipFox could not start"
            alert.informativeText = error.localizedDescription
            alert.runModal()
            NSApp.terminate(nil)
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor?.stop()
        hotKeyController?.stop()
    }
}

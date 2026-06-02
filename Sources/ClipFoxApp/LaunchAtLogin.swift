import Foundation
import ServiceManagement

@MainActor
enum LaunchAtLogin {
    static var isAvailable: Bool {
        // SMAppService only works for proper .app bundles installed in a real
        // location (typically /Applications). The SwiftPM `swift run` build
        // produces a raw executable, so we hide the toggle in that case.
        Bundle.main.bundlePath.hasSuffix(".app")
    }

    static var isEnabled: Bool {
        guard isAvailable else { return false }
        return SMAppService.mainApp.status == .enabled
    }

    static func setEnabled(_ enabled: Bool) throws {
        guard isAvailable else {
            throw LaunchAtLoginError.unavailable
        }
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }
    }
}

enum LaunchAtLoginError: LocalizedError {
    case unavailable

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Launch at login requires the installed ClipFox.app bundle, not the dev build."
        }
    }
}

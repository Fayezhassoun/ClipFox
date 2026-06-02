import AppKit
import ClipFoxCore
import CryptoKit
import Foundation

struct ObsidianSettings: Sendable, Equatable {
    var vaultPath: String
    var vaultName: String
    var inboxRelativePath: String

    static let `default` = ObsidianSettings(
        vaultPath: ("~/Documents/Fox" as NSString).expandingTildeInPath,
        vaultName: "Fox",
        inboxRelativePath: "Memory/Clipboard/Inbox.md"
    )

    var vaultURL: URL {
        URL(fileURLWithPath: vaultPath, isDirectory: true)
    }

    var inboxURL: URL {
        vaultURL.appendingPathComponent(inboxRelativePath)
    }
}

enum ObsidianBridgeError: LocalizedError {
    case vaultMissing(String)
    case duplicate
    case ioFailed(String)
    case urlSchemeFailed

    var errorDescription: String? {
        switch self {
        case .vaultMissing(let path):
            return "Obsidian vault not found at \(path)."
        case .duplicate:
            return "Clip already in Obsidian inbox."
        case .ioFailed(let detail):
            return "Could not write to Obsidian inbox: \(detail)"
        case .urlSchemeFailed:
            return "Could not open Obsidian. Is it installed?"
        }
    }
}

protocol ObsidianBridging: Sendable {
    func appendToInbox(_ item: ClipboardItem) throws
    func openAsNewNote(_ item: ClipboardItem) throws
}

struct ObsidianBridge: ObsidianBridging {
    let settings: ObsidianSettings

    init(settings: ObsidianSettings = .default) {
        self.settings = settings
    }

    func appendToInbox(_ item: ClipboardItem) throws {
        let vaultURL = settings.vaultURL
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: vaultURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            throw ObsidianBridgeError.vaultMissing(vaultURL.path)
        }

        let inboxURL = settings.inboxURL
        let inboxDir = inboxURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: inboxDir, withIntermediateDirectories: true)
        } catch {
            throw ObsidianBridgeError.ioFailed(error.localizedDescription)
        }

        let sha = Self.shortSHA(item.text)
        let existing = (try? String(contentsOf: inboxURL, encoding: .utf8)) ?? ""

        if existing.contains("<!-- clipfox-sha: \(sha) -->") {
            throw ObsidianBridgeError.duplicate
        }

        let entry = Self.renderEntry(item: item, sha: sha)
        let header = existing.isEmpty ? "# Clipboard Inbox\n\nAppended automatically by ClipFox.\n" : ""
        let payload = header + entry

        do {
            if existing.isEmpty {
                try payload.write(to: inboxURL, atomically: true, encoding: .utf8)
            } else {
                guard let data = payload.data(using: .utf8) else {
                    throw ObsidianBridgeError.ioFailed("encoding")
                }
                let handle = try FileHandle(forWritingTo: inboxURL)
                defer { try? handle.close() }
                try handle.seekToEnd()
                try handle.write(contentsOf: data)
            }
        } catch let error as ObsidianBridgeError {
            throw error
        } catch {
            throw ObsidianBridgeError.ioFailed(error.localizedDescription)
        }
    }

    func openAsNewNote(_ item: ClipboardItem) throws {
        let stamp = Self.fileTimestamp.string(from: Date())
        let title = item.title.prefix(40).replacingOccurrences(of: "/", with: "-")
        let name = "Clipboard \(stamp) — \(title)"

        var components = URLComponents()
        components.scheme = "obsidian"
        components.host = "new"
        components.queryItems = [
            URLQueryItem(name: "vault", value: settings.vaultName),
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "content", value: Self.renderNoteBody(item: item))
        ]

        guard let url = components.url, NSWorkspace.shared.open(url) else {
            throw ObsidianBridgeError.urlSchemeFailed
        }
    }

    private static func renderEntry(item: ClipboardItem, sha: String) -> String {
        let stamp = humanTimestamp.string(from: item.lastCopiedAt)
        let firstLine = item.title.replacingOccurrences(of: "\n", with: " ")
        let body = item.text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { "> \($0)" }
            .joined(separator: "\n")

        return """

        - \(stamp) — \(firstLine)
        > [!quote]- full clip
        \(body)
        <!-- clipfox-sha: \(sha) -->

        """
    }

    private static func renderNoteBody(item: ClipboardItem) -> String {
        let stamp = humanTimestamp.string(from: item.lastCopiedAt)
        return """
        ---
        source: clipfox
        captured: \(stamp)
        ---

        \(item.text)
        """
    }

    private static func shortSHA(_ text: String) -> String {
        let digest = SHA256.hash(data: Data(text.utf8))
        return digest.prefix(6).map { String(format: "%02x", $0) }.joined()
    }

    private static let humanTimestamp: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }()

    private static let fileTimestamp: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH-mm-ss"
        return f
    }()
}

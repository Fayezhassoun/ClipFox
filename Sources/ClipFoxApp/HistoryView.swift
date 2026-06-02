import ClipFoxCore
import SwiftUI

struct HistoryView: View {
    @ObservedObject var state: AppState
    let onClose: () -> Void

    @FocusState private var isSearchFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            if state.visibleItems.isEmpty {
                emptyState
            } else {
                List(selection: $state.selectedID) {
                    ForEach(state.visibleItems) { item in
                        ClipboardRow(item: item)
                            .tag(item.id)
                            .contextMenu {
                                Button(item.isPinned ? "Unpin" : "Pin") {
                                    state.togglePin(item)
                                }
                                Button("Copy") {
                                    state.copy(item, pasteAfterCopy: false)
                                }
                                Button("Paste") {
                                    state.copy(item)
                                    onClose()
                                }
                                Divider()
                                Button("Delete", role: .destructive) {
                                    state.delete(item)
                                }
                            }
                            .onTapGesture(count: 2) {
                                state.copy(item)
                                onClose()
                            }
                    }
                }
                .listStyle(.inset)
            }

            Divider()
            footer
        }
        .frame(minWidth: 460, idealWidth: 560, minHeight: 420, idealHeight: 560)
        .background(.regularMaterial)
        .onAppear {
            isSearchFocused = true
            state.selectedID = state.visibleItems.first?.id
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "paperclip")
                .font(.title3)
                .foregroundStyle(.secondary)

            TextField("Search clipboard history", text: $state.query)
                .textFieldStyle(.plain)
                .font(.system(size: 18, weight: .medium))
                .focused($isSearchFocused)
                .onChange(of: state.query) { _, _ in
                    state.selectedID = state.visibleItems.first?.id
                }

            Button {
                state.query = ""
            } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .opacity(state.query.isEmpty ? 0 : 1)
        }
        .padding(14)
    }

    private var footer: some View {
        HStack {
            if let error = state.lastError {
                Text(error)
                    .foregroundStyle(.red)
                    .lineLimit(1)
            } else {
                Text("\(state.history.items.count) items")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Label(state.cloudStatus.title, systemImage: cloudStatusIcon)
                .foregroundStyle(cloudStatusColor)
                .help(state.cloudStatus.detail ?? state.cloudStatus.title)

            Button {
                Task {
                    await state.refreshCloudStatus()
                    await state.syncWithCloud()
                }
            } label: {
                Image(systemName: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.borderless)
            .disabled(!state.cloudStatus.canSync)
            .help("Sync with iCloud")

            Button("Clear Unpinned") {
                state.clearUnpinned()
            }
            .disabled(state.history.items.allSatisfy(\.isPinned))

            Button("Close") {
                onClose()
            }
            .keyboardShortcut(.escape)
        }
        .font(.caption)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    private var cloudStatusIcon: String {
        switch state.cloudStatus {
        case .available:
            return "icloud"
        case .syncing, .checking:
            return "icloud.and.arrow.up"
        case .signedOut:
            return "person.crop.circle.badge.exclamationmark"
        case .restricted, .failed, .unavailable:
            return "icloud.slash"
        }
    }

    private var cloudStatusColor: Color {
        switch state.cloudStatus {
        case .available:
            return .green
        case .syncing, .checking:
            return .blue
        case .signedOut, .restricted, .failed, .unavailable:
            return .secondary
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 42))
                .foregroundStyle(.tertiary)

            Text(state.query.isEmpty ? "Clipboard history is empty" : "No matching clips")
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ClipboardRow: View {
    let item: ClipboardItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.isPinned ? "pin.fill" : "text.alignleft")
                .frame(width: 20)
                .foregroundStyle(item.isPinned ? .orange : .secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 14, weight: .medium))
                    .lineLimit(2)

                Text(metaText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text("\(item.copyCount)x")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    private var metaText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: item.lastCopiedAt, relativeTo: Date())
    }
}

import ClipFoxCore
import Foundation

#if canImport(CloudKit)
@preconcurrency import CloudKit
#endif

protocol CloudClipboardSyncing: Sendable {
    func accountStatus() async -> CloudSyncStatus
    func sync(history: ClipboardHistory) async throws -> [ClipboardItem]
}

struct CloudClipboardSync: CloudClipboardSyncing {
    #if canImport(CloudKit)
    private let containerIdentifier: String

    init(containerIdentifier: String = "iCloud.com.fayez.clipfox") {
        self.containerIdentifier = containerIdentifier
    }

    func accountStatus() async -> CloudSyncStatus {
        guard hasRunnableAppIdentity else {
            return .failed("iCloud sync needs a signed app bundle with the CloudKit entitlement.")
        }

        do {
            switch try await CKContainer(identifier: containerIdentifier).accountStatus() {
            case .available:
                return .available
            case .noAccount:
                return .signedOut
            case .restricted:
                return .restricted
            case .couldNotDetermine, .temporarilyUnavailable:
                return .failed("Could not determine iCloud account status.")
            @unknown default:
                return .failed("Unknown iCloud account status.")
            }
        } catch {
            return .failed(error.localizedDescription)
        }
    }

    func sync(history: ClipboardHistory) async throws -> [ClipboardItem] {
        guard hasRunnableAppIdentity else {
            throw CloudSyncError.missingEntitlement
        }

        let database = CKContainer(identifier: containerIdentifier).privateCloudDatabase
        try await upload(history.items)
        return try await fetchItems(in: database)
    }

    private func upload(_ items: [ClipboardItem]) async throws {
        let database = CKContainer(identifier: containerIdentifier).privateCloudDatabase

        for item in items {
            let record = CKRecord(recordType: "ClipboardItem", recordID: CKRecord.ID(recordName: item.id.uuidString))
            record["text"] = item.text as CKRecordValue
            record["createdAt"] = item.createdAt as CKRecordValue
            record["lastCopiedAt"] = item.lastCopiedAt as CKRecordValue
            record["isPinned"] = item.isPinned as CKRecordValue
            record["copyCount"] = item.copyCount as CKRecordValue
            _ = try await database.save(record)
        }
    }

    private func fetchItems(in database: CKDatabase) async throws -> [ClipboardItem] {
        let query = CKQuery(recordType: "ClipboardItem", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "lastCopiedAt", ascending: false)]

        let result = try await database.records(matching: query, resultsLimit: 400)
        return result.matchResults.compactMap { _, recordResult in
            guard case .success(let record) = recordResult else {
                return nil
            }
            return ClipboardItem(record: record)
        }
    }

    private var hasRunnableAppIdentity: Bool {
        guard Bundle.main.bundleIdentifier != nil else {
            return false
        }

        return true
    }
    #else
    init(containerIdentifier: String = "iCloud.com.fayez.clipfox") {}

    func accountStatus() async -> CloudSyncStatus {
        .unavailable
    }

    func sync(history: ClipboardHistory) async throws -> [ClipboardItem] {
        []
    }
    #endif
}

enum CloudSyncError: LocalizedError {
    case missingEntitlement

    var errorDescription: String? {
        switch self {
        case .missingEntitlement:
            return "iCloud sync needs a signed app bundle with the CloudKit entitlement."
        }
    }
}

#if canImport(CloudKit)
private extension ClipboardItem {
    init?(record: CKRecord) {
        guard
            let text = record["text"] as? String,
            let createdAt = record["createdAt"] as? Date,
            let lastCopiedAt = record["lastCopiedAt"] as? Date
        else {
            return nil
        }

        self.init(
            id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
            text: text,
            createdAt: createdAt,
            lastCopiedAt: lastCopiedAt,
            isPinned: (record["isPinned"] as? Bool) ?? false,
            copyCount: (record["copyCount"] as? Int) ?? 1
        )
    }
}
#endif

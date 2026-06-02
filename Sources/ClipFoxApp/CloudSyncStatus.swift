import Foundation

enum CloudSyncStatus: Equatable {
    case unavailable
    case checking
    case available
    case syncing
    case signedOut
    case restricted
    case failed(String)

    var title: String {
        switch self {
        case .unavailable:
            return "iCloud unavailable"
        case .checking:
            return "Checking iCloud"
        case .available:
            return "iCloud ready"
        case .syncing:
            return "Syncing iCloud"
        case .signedOut:
            return "Sign in to iCloud"
        case .restricted:
            return "iCloud restricted"
        case .failed:
            return "iCloud sync failed"
        }
    }

    var detail: String? {
        switch self {
        case .failed(let message):
            return message
        default:
            return nil
        }
    }

    var canSync: Bool {
        switch self {
        case .available, .failed:
            return true
        default:
            return false
        }
    }
}

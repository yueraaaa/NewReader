import Combine
import Foundation

/// Observes the iCloud account state and surfaces it for the UI.
///
/// The hard part of CloudKit sync (record upload, conflict resolution, push
/// notifications) is handled by SwiftData + the OS. This monitor is intentionally
/// lightweight: it answers "is the user signed in?" and "is sync configured?",
/// which is all the settings UI needs.
@MainActor
public final class SyncMonitor: ObservableObject {

    public enum AccountState: Equatable {
        case unknown
        case signedOut
        case signedIn
    }

    @Published public private(set) var accountState: AccountState = .unknown
    @Published public private(set) var lastEvent: Date?
    public let configuredContainerID: String?

    private var cancellable: AnyCancellable?

    public init(configuredContainerID: String?) {
        self.configuredContainerID = configuredContainerID
        refresh()
        observeAccountChanges()
    }

    public func refresh() {
        if FileManager.default.ubiquityIdentityToken != nil {
            accountState = .signedIn
        } else {
            accountState = .signedOut
        }
        lastEvent = Date()
    }

    /// True only when both the app is configured for CloudKit and the user
    /// is signed in. The settings UI uses this to show a one-line summary.
    public var isCloudSyncActive: Bool {
        configuredContainerID != nil && accountState == .signedIn
    }

    private func observeAccountChanges() {
        cancellable = NotificationCenter.default
            .publisher(for: .NSUbiquityIdentityDidChange)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
    }
}

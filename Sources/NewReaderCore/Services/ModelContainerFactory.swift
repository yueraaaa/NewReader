import Foundation
import SwiftData

/// Builds the app's `ModelContainer` with a graceful three-tier fallback:
/// 1. CloudKit-backed private database (when an iCloud container is configured
///    and the entitlement is present).
/// 2. Local-only persistent store (no CloudKit, but durable).
/// 3. In-memory (last resort, e.g. corrupt local store).
///
/// CloudKit sync requirements the schema already satisfies:
/// - All `@Model` properties are optional or have default values.
/// - All relationships are optional with explicit inverses.
/// - No `.unique` attributes.
///
/// Even with the entitlement, sync silently no-ops when the user is signed
/// out of iCloud — SwiftData handles the pause; we just log it.
public enum ModelContainerFactory {

    public struct Options: Sendable {
        /// Private database container identifier, e.g. `iCloud.com.newreader.app`.
        /// Set to `nil` to disable CloudKit.
        public var iCloudContainerID: String?

        public init(iCloudContainerID: String? = nil) {
            self.iCloudContainerID = iCloudContainerID
        }
    }

    public struct Result {
        public let container: ModelContainer
        public let mode: Mode
    }

    public enum Mode: Equatable {
        case cloudKit(containerID: String)
        case localPersistent
        case inMemory
    }

    /// Build a container, preferring CloudKit when configured.
    /// The caller is responsible for handling `mode` (e.g. surfacing in UI).
    public static func makeContainer(
        schema: Schema,
        options: Options = .init(),
        logger: (String) -> Void = { print("[NewReader] \($0)") }
    ) -> Result {
        // Tier 1: CloudKit — uses .automatic so SwiftData auto-detects
        // entitlements. Without a valid iCloud entitlement the store operates
        // as local-only, which is exactly what we want for ad-hoc / debug builds.
        if options.iCloudContainerID != nil {
            do {
                let config = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .automatic
                )
                let container = try ModelContainer(for: schema, configurations: config)
                logger("CloudKit store ready.")
                return Result(container: container, mode: .cloudKit(containerID: options.iCloudContainerID ?? "unknown"))
            } catch {
                logger("CloudKit init failed (\(error.localizedDescription)). Falling back to local-only.")
            }
        }

        // Tier 2: Local persistent
        do {
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            let container = try ModelContainer(for: schema, configurations: config)
            logger("Local persistent container ready.")
            return Result(container: container, mode: .localPersistent)
        } catch {
            logger("Local persistent init failed (\(error.localizedDescription)). Falling back to in-memory.")
        }

        // Tier 3: In-memory (data will not persist across launches)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: config)
        logger("In-memory container ready (no persistence).")
        return Result(container: container, mode: .inMemory)
    }
}

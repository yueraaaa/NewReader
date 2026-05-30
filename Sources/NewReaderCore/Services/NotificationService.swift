import Foundation
#if canImport(UserNotifications)
import UserNotifications
#endif

/// Manages local notifications for new articles
public final class NotificationService: NSObject, @unchecked Sendable {
    public static let shared = NotificationService()

    private override init() {
        super.init()
    }

    /// Request notification permissions
    public func requestPermission() async -> Bool {
        #if os(macOS)
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
        #else
        return false
        #endif
    }

    /// Send a notification for a batch of new articles
    public func notifyNewArticles(_ articles: [(title: String, feedTitle: String)]) {
        #if os(macOS)
        guard !articles.isEmpty else { return }

        let content = UNMutableNotificationContent()

        if articles.count == 1 {
            content.title = articles[0].feedTitle
            content.body = articles[0].title
        } else {
            content.title = "\(articles.count) 篇新文章"
            content.body = articles.prefix(3).map { $0.title }.joined(separator: "\n")
        }

        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
        #endif
    }

    /// Clear all delivered notifications
    public func clearAll() {
        #if os(macOS)
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        #endif
    }
}

#if os(macOS)
extension NotificationService: UNUserNotificationCenterDelegate {
    public nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
#endif

import Foundation
import UserNotifications

struct CitrusNotificationCenter: Sendable {
    func requestAuthorizationIfNeeded() async {
        guard canUseUserNotifications else { return }

        do {
            _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        } catch {
            // Authorization failure should not block local processing.
        }
    }

    func notifyJobCompleted(fileName: String) async {
        guard canUseUserNotifications else { return }

        let content = UNMutableNotificationContent()
        content.title = "Citrus finished"
        content.body = "\(fileName) is ready."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        try? await UNUserNotificationCenter.current().add(request)
    }

    private var canUseUserNotifications: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }
}

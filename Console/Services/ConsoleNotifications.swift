import Foundation
import Combine
import UIKit
import UserNotifications

extension Notification.Name {
    static let consolePushTokenUpdated = Notification.Name("console.push-token-updated")
    static let consoleRemoteEvent = Notification.Name("console.remote-event")
}

@MainActor
final class ConsoleNotifications: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = ConsoleNotifications()

    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var lastRegistrationError: String?

    private let tokenKey = "console.push.deviceToken"

    var deviceToken: String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }

    var statusTitle: String {
        switch authorizationStatus {
        case .notDetermined: return "Не настроены"
        case .denied: return "Отключены"
        case .authorized: return "Разрешены"
        case .provisional: return "Тихие уведомления"
        case .ephemeral: return "Временный доступ"
        @unknown default: return "Неизвестно"
        }
    }

    func configure() {
        UNUserNotificationCenter.current().delegate = self
        Task { await refreshAuthorizationStatus() }
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await refreshAuthorizationStatus()
            if granted {
                UIApplication.shared.registerForRemoteNotifications()
            }
            return granted
        } catch {
            lastRegistrationError = error.localizedDescription
            return false
        }
    }

    func registerForRemoteNotificationsIfAuthorized() async {
        await refreshAuthorizationStatus()
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else { return }
        UIApplication.shared.registerForRemoteNotifications()
    }

    func didRegister(deviceToken data: Data) {
        let token = data.map { String(format: "%02x", $0) }.joined()
        UserDefaults.standard.set(token, forKey: tokenKey)
        lastRegistrationError = nil
        NotificationCenter.default.post(name: .consolePushTokenUpdated, object: token)
    }

    func didFailRegistration(_ error: Error) {
        lastRegistrationError = error.localizedDescription
    }

    func postLocal(title: String, body: String, category: String = "console.activity") {
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.threadIdentifier = category
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        await MainActor.run {
            NotificationCenter.default.post(
                name: .consoleRemoteEvent,
                object: nil,
                userInfo: notification.request.content.userInfo
            )
        }
        return [.banner, .sound, .badge]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        await MainActor.run {
            NotificationCenter.default.post(
                name: .consoleRemoteEvent,
                object: nil,
                userInfo: response.notification.request.content.userInfo
            )
        }
    }
}

final class ConsoleAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Task { @MainActor in
            ConsoleNotifications.shared.configure()
            await ConsoleNotifications.shared.registerForRemoteNotificationsIfAuthorized()
        }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { @MainActor in
            ConsoleNotifications.shared.didRegister(deviceToken: deviceToken)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Task { @MainActor in
            ConsoleNotifications.shared.didFailRegistration(error)
        }
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task { @MainActor in
            NotificationCenter.default.post(name: .consoleRemoteEvent, object: nil, userInfo: userInfo)
        }
        completionHandler(.newData)
    }
}

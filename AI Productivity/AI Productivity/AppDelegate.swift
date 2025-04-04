import UIKit
import GoogleSignIn
import Firebase
import FirebaseCore
import FirebaseStorage
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Set UNUserNotificationCenter delegate to self
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Clear delivered notifications.
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        // Optionally, clear any pending notification requests.
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    // MARK: UISceneSession Lifecycle
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(
        _ application: UIApplication,
        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
    ) { }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // This method is called when a notification is delivered while the app is in the foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Present the notification as a banner with sound.
        completionHandler([.banner, .sound, .badge])
    }
}

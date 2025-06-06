//
//  AppDelegate.swift
//  Focus
//
//  Created by Максим Зыкин on 09.02.2025.
//

import UIKit
import BackgroundTasks
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let center = UNUserNotificationCenter.current()
        center.delegate = self

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            print("Разрешение: \(granted)")

            center.getNotificationSettings { settings in
                print("authorizationStatus: \(settings.authorizationStatus.rawValue)")

                if settings.authorizationStatus == .authorized {
                    // Тестовое уведомление через 5 секунд
                    let content = UNMutableNotificationContent()
                    content.title = "Тест"
                    content.body = "Работает!"
                    content.sound = .default

                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                    let request = UNNotificationRequest(identifier: "testNotification", content: content, trigger: trigger)

                    center.add(request) { error in
                        if let error = error {
                            print("Ошибка добавления уведомления: \(error.localizedDescription)")
                        } else {
                            print("Уведомление добавлено")
                        }
                    }
                }
            }
        }

        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) { }
}



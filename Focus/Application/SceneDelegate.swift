//
//  SceneDelegate.swift
//  Focus
//
//  Created by Максим Зыкин on 09.02.2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    var homeModel = HomeViewControllerModel()
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScrean = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScrean)
        let vc = HomeViewController()
        let navC = UINavigationController(rootViewController: vc)
        window.rootViewController = navC
        
        self.window = window
        window.makeKeyAndVisible()
    }
    
//    func applicationDidEnterBackground(_ application: UIApplication) {
//        guard let window = window else { return }
//        
//        // Находим HomeViewController в иерархии
//        if let navController = window.rootViewController as? UINavigationController,
//           let homeVC = navController.viewControllers.first as? HomeViewController {
//            homeVC.modelInstance.saveStateBeforeBackground()
//        } else if let homeVC = window.rootViewController as? HomeViewController {
//            homeVC.modelInstance.saveStateBeforeBackground()
//        }
//        
//        // Альтернативный вариант через NotificationCenter
//        NotificationCenter.default.post(name: NSNotification.Name("AppEnteredBackground"), object: nil)
//    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        if let navC = window?.rootViewController as? UINavigationController,
           let homeVC = navC.viewControllers.first as? HomeViewController {
            //homeVC.modelInstance.scheduleFullPomodoroSessionNotifications()
        }

    }



}


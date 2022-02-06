//
//  AppDelegate.swift
//  AVPlayerProject
//
//  Created by Ray Migneco on 2/6/22.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    let manager = PlayerManager.shared

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        manager.delegate = self
        manager.loadInitialResource()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

extension AppDelegate: PlayerManagerObservable {
    
    func managerIsReadyToPlay(_ manager: PlayerManager) {
        print("Player Manager Status: Ready")
        manager.play()
    }
    
    func managerDidFail(_ manager: PlayerManager, with error: Error?) {
        print("Player Manager Status- Failed with Error: \(String(describing: error))")
    }
    
    func managerStatusUnknown(_ manager: PlayerManager) {
        print("Player Manager Status: Unknown")
    }
    
    func managerFailedToLoadResource(message: String) {
        print("Player Manager Failed To Load: \(message)")
    }
}


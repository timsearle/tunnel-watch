//
//  TunnelWatchApp.swift
//  TunnelWatch
//
//  Created by Tim Searle on 01/01/2026.
//

import CarPlay
import UIKit

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        if connectingSceneSession.role == .carTemplateApplication {
            let config = UISceneConfiguration(name: "CarPlay", sessionRole: connectingSceneSession.role)
            config.sceneClass = NSClassFromString("CPTemplateApplicationScene")
            config.delegateClass = CarPlaySceneDelegate.self
            return config
        }

        let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

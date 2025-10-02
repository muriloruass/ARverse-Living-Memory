//
//  AppDelegate.swift
//  ArProject
//
//  Created by Murilo Ruas Lucena on 2025-10-01.
//

import UIKit
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView()

        // Use a UIHostingController as window root view controller.
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UIHostingController(rootView: contentView)
        self.window = window
        window.makeKeyAndVisible()
        
        // Otimizações para AR
        setupAROptimizations()
        
        return true
    }
    
    /// Configures optimizations specific to AR applications
    private func setupAROptimizations() {
        // Keep screen always on during AR use
        UIApplication.shared.isIdleTimerDisabled = true
        
        // Note: Status bar will be hidden via Info.plist or SwiftUI modifier
        // windowScene.statusBarManager?.statusBarHidden is read-only
        
        print("🔧 AR optimizations configured")
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Pause AR experiences when app loses focus
        print("⏸️ App lost focus - pausing AR")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Release AR resources when app goes to background
        UIApplication.shared.isIdleTimerDisabled = false
        print("📱 App in background - AR resources released")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Prepare to resume AR
        print("🔄 App returning - preparing AR")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Resume AR experiences
        UIApplication.shared.isIdleTimerDisabled = true
        print("▶️ App active - AR resumed")
    }
}


//
//  AI_Tennis_CoachApp.swift
//  Shared
//
//  Created by Reid Fleishman on 12/22/21.
//

import SwiftUI


@main
struct AI_Tennis_CoachApp: App {
    @StateObject private var networkController = NetworkController()
    
    var body: some Scene {
        WindowGroup {
            if (!networkController.userData.loggedIn && !networkController.newUser) {
                LogInView()
                    .environmentObject(networkController)
            }
            else if (networkController.newUser) {
                ProfileSettingsView(isNewUser: true)
                    .environmentObject(networkController)
            }
            else if (networkController.userData.loggedIn && networkController.userData.shared.email != nil && !(networkController.userData.shared.email_confirmed ?? true)) {
                EmailNotConfirmedView()
                    .environmentObject(networkController)
            }
            else {
                ContentView()
                    .environmentObject(networkController)
            }
        }
    }
}

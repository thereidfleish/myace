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
            // If the user is not logged in AND the user hasn't initiated a showOnboarding (only shown when it's a new user), then show the login screen
            if (!networkController.userData.loggedIn && !networkController.userData.showOnboarding) {
                LogInView()
                    .environmentObject(networkController)
            }
            else if (!networkController.userData.showOnboarding && )
            else if (networkController.userData.showOnboarding) {
                OnboardingView(showProfileSettingsView: true)
                    .environmentObject(networkController)
            }
//            else if (networkController.userData.loggedIn && networkController.userData.shared.email != nil && !(networkController.userData.shared.email_confirmed ?? true)) {
//                EmailNotConfirmedView()
//                    .environmentObject(networkController)
//            }
//            else if (networkController.showOnboarding) {
//                OnboardingView()
//                    .environmentObject(networkController)
//            }
            else {
                ContentView()
                    .environmentObject(networkController)
            }
        }
    }
}

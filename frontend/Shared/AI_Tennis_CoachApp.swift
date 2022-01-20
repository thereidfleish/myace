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
            if (networkController.userData.shared.type == -1 && !networkController.newUser) {
                LogInView()
                    .environmentObject(networkController)
            }
            else if (networkController.newUser) {
                NewUserOnboardingView()
                    .environmentObject(networkController)
            }
            else {
                ContentView()
                    .environmentObject(networkController)
            }
        }
    }
}

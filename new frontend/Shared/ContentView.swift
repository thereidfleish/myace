//
//  ContentView.swift
//  Shared
//
//  Created by Reid Fleishman on 12/22/21.
//

import SwiftUI

struct ContentView: View {
    @State private var selection = 0
    @EnvironmentObject private var networkController: NetworkController
    var body: some View {
        ZStack {
            TabView(selection: $selection) {
                FeedView()
                    .tabItem {
                        VStack {
                            Image(systemName: "rectangle.stack.badge.play.fill")
                                .foregroundColor(.green)
                            Text("Feed")
                                .foregroundColor(.green)
                        }
                    }
                    .tag(0)
                
                SpacesView()
                        .tabItem {
                            VStack {
                                Image(systemName: "person.3.fill")
                                    .foregroundColor(.green)
                                Text("Courtships")
                                    .foregroundColor(.green)
                            }
                        }
                        .tag(1)
                
                SearchView()
                    .tabItem {
                        VStack {
                            Image(systemName: "magnifyingglass.circle.fill")
                                .foregroundColor(.green)
                            Text("Search")
                                .foregroundColor(.green)
                        }
                    }
                    .tag(3)
                
                NavigationView {
                    ProfileView(yourself: true, user: networkController.userData.shared)
                }
                .navigationViewStyle(StackNavigationViewStyle()) // helps with Jumping Back bug
                .tabItem {
                    VStack {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundColor(.green)
                        Text("My Profile")
                            .foregroundColor(.green)
                    }
                }
                .tag(4)
                
                
                
            }.accentColor(Color.green)
            
            if (networkController.showingMessage) {
                networkController.messageView
            }
        }
    }
}



//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}

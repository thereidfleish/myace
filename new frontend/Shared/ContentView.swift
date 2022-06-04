//
//  ContentView.swift
//  Shared
//
//  Created by Reid Fleishman on 12/22/21.
//

import SwiftUI

struct ContentView: View {
    @State private var selection = 0
    //@StateObject var studentInfo = StudentInfo()
    //@StateObject var coachInfo = CoachInfo()
    @EnvironmentObject private var networkController: NetworkController
    var body: some View {
        TabView(selection: $selection) {
            StudentUploadView(currentUserAs: .student)
                    .tabItem {
                        VStack {
                            Image(systemName: "rectangle.inset.filled.and.person.filled")
                                .foregroundColor(.green)
                            Text("Your Coaches")
                                .foregroundColor(.green)
                        }
                    }
                    .tag(0)
            
            StudentUploadView(currentUserAs: .coach)
                    .tabItem {
                        VStack {
                            Image(systemName: "graduationcap.fill")
                                .foregroundColor(.green)
                            Text("Your Students")
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
                .tag(2)
            
            NavigationView {
                ProfileView(yourself: true, user: networkController.userData.shared)
            }
            .navigationViewStyle(.stack) // helps with Jumping Back bug
            .tabItem {
                VStack {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundColor(.green)
                    Text("My Profile")
                        .foregroundColor(.green)
                }
            }
            .tag(3)
            
            
            
        }.accentColor(Color.green)
    }
}



//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}

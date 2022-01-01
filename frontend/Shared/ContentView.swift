//
//  ContentView.swift
//  Shared
//
//  Created by Reid Fleishman on 12/22/21.
//

import SwiftUI

struct ContentView: View {
    @State private var selection = 0
    @StateObject var studentInfo = StudentInfo()
    @StateObject var coachInfo = CoachInfo()
    @EnvironmentObject private var networkController: NetworkController
    
    var body: some View {
        TabView(selection: $selection) {
            if (networkController.userData.shared.type == 0) {
                StudentUploadView()
                    .environmentObject(studentInfo)
                    .environmentObject(coachInfo)
                    .tabItem {
                        VStack {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .foregroundColor(.green)
                            Text("Student View")
                                .foregroundColor(.green)
                        }
                    }
                    .tag(0)
            }
            else {
                CoachMainView()
                    .environmentObject(coachInfo)
                    .environmentObject(studentInfo)
                    .tabItem {
                        VStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.green)
                            Text("Coach View")
                                .foregroundColor(.green)
                        }
                    }
                    .tag(0)
            }
            
            
        }.accentColor(Color.green)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

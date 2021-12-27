//
//  ContentView.swift
//  Shared
//
//  Created by Reid Fleishman on 12/22/21.
//

import SwiftUI

struct ContentView: View {
    @State private var selection = 0
    var studentInfo = StudentInfo()
    var coachInfo = CoachInfo()
    
    var body: some View {
        TabView(selection: $selection) {
            StudentUploadView() // Will need to add logic to show this view or another one based on if its a student or a coach logged in
                .environmentObject(studentInfo)
                .environmentObject(coachInfo)
                .tabItem {
                    VStack {
                        Image(systemName: "square.and.arrow.up.circle.fill")
                        Text("Student View")
                    }
            }
            .tag(0)
            
            CoachMainView()
                .environmentObject(coachInfo)
                .environmentObject(studentInfo)
                .tabItem {
                    VStack {
                        Image(systemName: "person.circle.fill")
                        Text("Coach View")
                    }
            }
            .tag(1)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

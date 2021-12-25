//
//  ContentView.swift
//  Shared
//
//  Created by Reid Fleishman on 12/22/21.
//

import SwiftUI

struct ContentView: View {
    @State private var selection = 0
    
    var body: some View {
        TabView(selection: $selection) {
            StudentUploadView() // Will need to add logic to show this view or another one based on if its a student or a coach logged in
                .tabItem {
                    VStack {
                        Image(systemName: "square.and.arrow.up.circle.fill")
                        Text("Uploads")
                    }
            }
            .tag(0)
            
//            MySessionsView()
//                .tabItem {
//                    VStack {
//                        Image(systemName: "calendar.badge.clock")
//                        Text("My Sessions")
//                    }
//            }
//            .tag(1)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

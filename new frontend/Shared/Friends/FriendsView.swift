//
//  FriendsView.swift
//  AI Tennis Coach
//
//  Created by AndrewC on 1/20/22.
//

import SwiftUI

struct FriendsView: View {
    @EnvironmentObject private var nc: NetworkController
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var awaiting = false
    @State private var didAppear = false
    @State var tabIndex = 0
    
    func initialize() async {
        do {
            awaiting = true
            try await nc.getCourtships(user_id: "me", type: nil)
            try await nc.getCourtshipRequests(type: nil, dir: "in", users: nil)
            try await nc.getCourtshipRequests(type: nil, dir: "out", users: nil)
            awaiting = false
        } catch {
            print(error)
            errorMessage = error.localizedDescription
            showingError = true
            awaiting = false
        }
    }
    
    var body: some View {
        VStack {
            if (awaiting) {
                ProgressView()
            } else if (showingError) {
                Text(nc.errorMessage).padding()
            } else {
                VStack {
                    Picker("", selection: $tabIndex) {
                        Text("Courtships").tag(0)
                        Text("Courtship Requests").tag(1)
                    } .pickerStyle(.segmented)
                    
                }.padding(.horizontal)
                
                ScrollView {
                    if tabIndex == 0 {
                        if nc.userData.courtships.count == 0 {
                            Text("Click the + icon to search for and add your courtships!")
                                .bucketTextInternalStyle()
                        }
                        ForEach(nc.userData.courtships, id: \.self.id) { courtship in
                            UserCardView(user: courtship)
                        }
                        
                    }
                    else  {
                        VStack(alignment: .leading) {
                            Text(nc.userData.incomingCourtshipRequests.count > 0 ? "Incoming Courtship Requests" : "No Incoming Courtship Requests")
                                .bucketTextInternalStyle()
                            
                            ForEach(nc.userData.incomingCourtshipRequests, id: \.self.id) { courtship in
                                UserCardView(user: courtship)
                            }
                            
                            Text(nc.userData.outgoingCourtshipRequests.count > 0 ? "Outgoing Courtship Requests" : "No Outgoing Courtship Requests")
                                .padding(.top)
                                .bucketTextInternalStyle()
                            
                            ForEach(nc.userData.outgoingCourtshipRequests, id: \.self.id) { courtship in
                                UserCardView(user: courtship)
                            }
                        }
                        
                    }
                    
                }.padding(.horizontal)
                    .navigationBarItems(trailing:
                                            NavigationLink(destination: SearchView().onAppear(perform: {didAppear = false})) {
                        Image(systemName: "plus")
                            .foregroundColor(Color.green)
                            .padding()
                    }
                                        
                                        
                                        
                    )
            }
        }.task {
            await initialize()
        }
        
        
        
        
    }
}





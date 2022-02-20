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
    
    func initialize() {
        if(!didAppear) {
            didAppear = true
            Task {
                do {
                    
                    awaiting = true
                    try await nc.getCourtships(type: nil, users: nil)
                    try await nc.getCourtshipRequests(type: nil, dir: nil, users: nil)
                    awaiting = false
                    print("DONE!")
                } catch {
                    print(error)
                    errorMessage = error.localizedDescription
                    showingError = true
                    awaiting = false
                }
            }
        }
        
    }
    
    var body: some View {
        VStack {
            if (awaiting) {
                ProgressView()
            } else if (showingError) {
                Text(UserData.computeErrorMessage(errorMessage: errorMessage)).padding()
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
                        ForEach(nc.userData.courtships) { courtship in
                            NavigationLink(destination: ProfileView(yourself: false, user: courtship.user).navigationBarHidden(true))
                            {
                                UserCardView(user: courtship.user)
                            }
                        }
                        
                    }
                    else  {
                        VStack(alignment: .leading) {
                            Text(nc.userData.courtshipRequests.contains(where: {$0.dir == "in"}) ? "Incoming Courtship Requests" : "No Incoming Courtship Requests")
                                .bucketTextInternalStyle()
                            
                            ForEach(nc.userData.courtshipRequests.filter({$0.dir == "in"})) { courtship in
                                NavigationLink(destination: ProfileView(yourself: false, user: courtship.user).navigationBarHidden(true))
                                {
                                    UserCardView(user: courtship.user)
                                }
                            }
                            
                            Text(nc.userData.courtshipRequests.contains(where: {$0.dir == "out"}) ? "Outgoing Courtship Requests" : "No Outgoing Courtship Requests")
                                .padding(.top)
                                .bucketTextInternalStyle()
                            
                            ForEach(nc.userData.courtshipRequests.filter({$0.dir == "out"})) { courtship in
                                NavigationLink(destination: ProfileView(yourself: false, user: courtship.user).navigationBarHidden(true))
                                {
                                    UserCardView(user: courtship.user)
                                }
                            }
                        }
                        
                    }
                    
                }.padding(.horizontal)
                    .navigationBarItems(trailing:
                                            HStack {
                        NavigationLink(destination: FriendRequests().onAppear(perform: {didAppear = false})) {
                            Image(systemName: "face.smiling")
                                .foregroundColor(Color.green)
                                .padding()
                        }
                        NavigationLink(destination: SearchView().onAppear(perform: {didAppear = false})) {
                            Image(systemName: "plus")
                                .foregroundColor(Color.green)
                                .padding()
                        }
                        
                        
                    }
                    )
            }
        }.onAppear(perform: {initialize()})
        
        
        
        
    }
}





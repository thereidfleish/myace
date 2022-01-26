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
                    try await nc.getFriends()
                    try await nc.getFriendRequests()
                    awaiting = false
                    print("DONE!")
                } catch {
                    print(error)
                    errorMessage = error.localizedDescription
                    showingError = true
                    awaiting = false
                }
                
                print(nc.userData.friends)
                print(nc.userData.incomingFriendRequests)
                print(nc.userData.outgoingFriendRequests)
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
                        Text("Friends").tag(0)
                        Text("Friend Requests").tag(1)
                    } .pickerStyle(.segmented)
                    
                }.padding(.horizontal)
                
                ScrollView {
                    if tabIndex == 0 {
                        if nc.userData.friends.count == 0 {
                            Text("Click the + icon to search for and add your friends!")
                                .bucketTextInternalStyle()
                        }
                        ForEach(nc.userData.friends) { user in
                            NavigationLink(destination: ProfileView(yourself: false, user: user).navigationBarHidden(true))
                            {
                                UserCardView(user: user)
                            }
                        }
                        
                    }
                    else  {
                        VStack(alignment: .leading) {
                            Text(nc.userData.incomingFriendRequests.count == 0 ? "No Incoming Friend Requests" : "Incoming Friend Requests")
                                .bucketTextInternalStyle()
                            
                            ForEach(nc.userData.incomingFriendRequests) { user in
                                NavigationLink(destination: ProfileView(yourself: false, user: user).navigationBarHidden(true))
                                {
                                    UserCardView(user: user)
                                }
                            }
                            
                            Text(nc.userData.outgoingFriendRequests.count == 0 ? "No Outgoing Friend Requests" : "Outgoing Requests")
                                .padding(.top)
                                .bucketTextInternalStyle()
                            
                            ForEach(nc.userData.outgoingFriendRequests) { user in
                                NavigationLink(destination: ProfileView(yourself: false, user: user).navigationBarHidden(true))
                                {
                                    UserCardView(user: user)
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





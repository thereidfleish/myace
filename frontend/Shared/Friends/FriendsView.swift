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
    @State var requestTabIndex = -1
    
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

            if (awaiting) {
                ProgressView()
            } else if (showingError) {
                Text(UserData.computeErrorMessage(errorMessage: errorMessage)).padding()
            } else {
                ScrollView {
                    VStack {
                        Picker("", selection: $tabIndex) {
                            Text("Friends").tag(0)
                            Text("Friend Requests").tag(1)
                        } .pickerStyle(.segmented)
                        if tabIndex == 0 {
                            FriendList()
                        }
                        else  {
                            /*
                            Picker("", selection: $requestTabIndex) {
                                Text("Incoming").tag(0)
                                Text("Outgoing").tag(1)
                            } .pickerStyle(.segmented)
                             
                            if requestTabIndex == 0 {
                                IncomingFriendRequestList()
                            }
                            else if requestTabIndex == 1{
                                OutgoingFriendRequestList()
                            }
                             */
                            Text("Incoming Requests")
                                .bucketNameStyle()
                                .foregroundColor(Color.green)
                            Spacer()
                            IncomingFriendRequestList()
                            Spacer()
                            Text("Outgoing Requests")
                                .bucketNameStyle()
                                .foregroundColor(Color.green)
                            Spacer()
                            OutgoingFriendRequestList()
                        }
                    }
                    .frame(alignment: .center)
                    .padding(.horizontal, 12)
                }
                .onAppear(perform: {initialize()})
                .padding(.leading, 1)
                .navigationBarItems(trailing: NavigationLink(destination: FriendRequests().onAppear(perform: {didAppear = false})) {
                    Image(systemName: "plus")
                        .foregroundColor(Color.green)
                        .padding()
                })
            }
                

    
  

    }
}





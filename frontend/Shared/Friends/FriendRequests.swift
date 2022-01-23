//
//  FriendRequests.swift
//  AI Tennis Coach
//
//  Created by AndrewC on 1/20/22.
//

/*
 
 for testing purposes only, will most likely be deleted after we link friend requests directly to the search bar instead
 
 
 
 
 */

import SwiftUI

struct FriendRequests: View {
    @EnvironmentObject private var nc: NetworkController
    @State private var requestedUserID: String = "-1"
    @State private var awaiting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    func createFriendRequest() {
        Task {
            do {
                awaiting = true
                try await nc.createFriendRequest(userID: requestedUserID)
                print("DONE!")
            } catch {
                print(error)
                errorMessage = error.localizedDescription
                showingError = true
            }
            awaiting = false
        }
    }
    
    var body: some View {
        VStack {
            Text("This view is for dev only and will be deprecated once search bar is available")
                .bucketTextInternalStyle()
            Spacer()
            Text("Type your friend's userID")
                .bucketTextInternalStyle()
            
            TextField("User ID", text: $requestedUserID)
                .textFieldStyle()
            
            Button(action: {
                if requestedUserID != "-1" {
                    createFriendRequest()
                }
            }, label: {
                Text("Request")
                    .buttonStyle()
            })
            Spacer()
            
        }.padding(.horizontal)
    }
}


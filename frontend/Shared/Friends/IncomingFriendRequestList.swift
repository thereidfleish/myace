//
//  IncomingFriendRequestList.swift
//  AI Tennis Coach
//
//  Created by AndrewC on 1/23/22.
//

import SwiftUI

struct IncomingFriendRequestList: View {
    @EnvironmentObject private var nc: NetworkController
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var awaiting = false
    func updateFriendRequest(status: String, userID: Int) {
        Task {
            do {
                
                awaiting = true
                try await nc.updateIncomingFriendRequest(status: status, userID: userID)
                try await nc.getFriends() // refresh friends tab
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
    var body: some View {
        VStack {
            if nc.userData.incomingFriendRequests.count == 0 {
                Text("You have no incoming friend requests.")
                    .bucketNameStyle()
                    .foregroundColor(Color.black)
            }
            ForEach(nc.userData.incomingFriendRequests) { request in
//                NavigationLink(destination: StudentUploadDetailView(student: true, bucketID: "\(bucket.id)").navigationTitle(bucket.name).navigationBarTitleDisplayMode(.inline))
//                {
                HStack {
                    VStack(alignment: .leading) {
                        Text(request.display_name)
                            .bucketNameStyle()
                            .foregroundColor(Color.white)
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(Color.white)
                                .frame(width: 15)
                            Text(request.username)
                                .bucketTextExternalStyle()
                        }
                    }
                    Spacer()
                    Button(action: {
                        updateFriendRequest(status: "accepted", userID: request.id)
                        if let index = nc.userData.incomingFriendRequests.firstIndex(of: request) {
                            nc.userData.incomingFriendRequests.remove(at: index)
                        }
                        
                    }, label: {
                        Image(systemName: "checkmark")
                            .resizable()
                            .scaledToFill()
                            .foregroundColor(Color.blue)
                            .frame(width: 20, height: 20)
                            .padding(.horizontal, 10)
                    })
                    Spacer()
                    Button(action: {
                        updateFriendRequest(status: "declined", userID: request.id)
                        if let index = nc.userData.incomingFriendRequests.firstIndex(of: request) {
                            nc.userData.incomingFriendRequests.remove(at: index)
                        }
                    }, label: {
                        Image(systemName: "xmark")
                            .resizable()
                            .scaledToFill()
                            .foregroundColor(Color.red)
                            .frame(width: 20, height: 20)
                            .padding(.horizontal, 10)
                        
                    })
           

                }
                .navigationLinkStyle()
//                }
            }
            Spacer()
            Spacer()
            Spacer()
        }
    }
}

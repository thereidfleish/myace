//
//  OutgoingFriendRequestList.swift
//  AI Tennis Coach
//
//  Created by AndrewC on 1/23/22.
//

import SwiftUI

struct OutgoingFriendRequestList: View {
    @EnvironmentObject private var nc: NetworkController
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var awaiting = false
    func deleteOutgoingFriendRequest(userID: Int) {
        Task {
            do {
                awaiting = true
                try await nc.deleteOutgoingFriendRequest(userID: userID)
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
            if nc.userData.outgoingFriendRequests.count == 0 {
                Text("You have no outgoing friend requests.")
                    .bucketNameStyle()
                    .foregroundColor(Color.black)
            }
            ForEach(nc.userData.outgoingFriendRequests) { request in
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
                        deleteOutgoingFriendRequest(userID: request.id)
                        if let index = nc.userData.outgoingFriendRequests.firstIndex(of: request) {
                            nc.userData.outgoingFriendRequests.remove(at: index)
                        }
                        
                    }, label: {
                        Text("Cancel")
                            .padding(.vertical, 2)
                            .padding(.horizontal, 5)
                            .frame(width: 70)
                            .background(Color.white)
                            .cornerRadius(10)
                            .foregroundColor(.green)
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



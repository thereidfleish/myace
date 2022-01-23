//
//  FriendList.swift
//  AI Tennis Coach
//
//  Created by AndrewC on 1/23/22.
//

import SwiftUI

struct FriendList: View {
    @EnvironmentObject private var nc: NetworkController
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var awaiting = false
    @State private var showRemoveFriendAlert = false
    @State private var selectedFriend: Friend = Friend(id: 0, username: "", display_name: "", type: -1)

    
    func removeFriend(userID: Int) {
        Task {
            do {
                awaiting = true
                try await nc.removeFriend(userID: userID)
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
            if nc.userData.friends.count == 0 {
                Text("You have no friends.")
                    .bucketNameStyle()
                    .foregroundColor(Color.black)
            }
            ForEach(nc.userData.friends) { friend in
//                NavigationLink(destination: StudentUploadDetailView(student: true, bucketID: "\(bucket.id)").navigationTitle(bucket.name).navigationBarTitleDisplayMode(.inline))
//                {
                HStack {
                    VStack(alignment: .leading) {
                        Text(friend.display_name)
                            .bucketNameStyle()
                            .foregroundColor(Color.white)
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(Color.white)
                                .frame(width: 15)
                            Text(friend.username)
                                .bucketTextExternalStyle()
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showRemoveFriendAlert = true
                        selectedFriend = friend
//                        removeFriend(userID: friend.id)
//                        if let index = nc.userData.friends.firstIndex(of: friend) {
//                            nc.userData.friends.remove(at: index)
//                        }
                    }, label: {
                        Text("Remove")
                            .padding(.vertical, 2)
                            .padding(.horizontal, 5)
                            .frame(width: 80)
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
        .alert("Are you sure you want to remove \(selectedFriend.display_name) (\(selectedFriend.username)) as a friend?", isPresented: $showRemoveFriendAlert) {
        Button("Cancel", role: .cancel) { }
        Button("Remove Friend", role: .destructive) {
            removeFriend(userID: selectedFriend.id)
            if let index = nc.userData.friends.firstIndex(of: selectedFriend) {
                nc.userData.friends.remove(at: index)
            }
        }
    }
    }
}


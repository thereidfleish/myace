//
//  UserCardView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 1/23/22.
//

import SwiftUI

struct UserCardView: View {
    @EnvironmentObject private var nc: NetworkController
    @State private var awaiting = false
    @State private var showingStatus = false
    @State private var statusMessage = ""
    @State var user: Friend
    @State private var showRemoveFriendAlert = false
    
    //@State private var
    
    func updateData() {
        Task {
            do {
                awaiting = true
                try await nc.getFriends()
                try await nc.getFriendRequests()
                awaiting = false
            } catch {
                statusMessage = error.localizedDescription
                showingStatus = true
                awaiting = false
            }
        }
    }
    
    func createFriendRequest(userID: String) {
        Task {
            do {
                awaiting = true
                try await nc.createFriendRequest(userID: userID)
                updateData()
                withAnimation {
                    statusMessage = userID == String(nc.userData.shared.id) ? "Lol you can't send a friend request to yourself!!" : "Sent friend request."
                    showingStatus = true
                }
                awaiting = false
            } catch {
                statusMessage = error.localizedDescription
                showingStatus = true
                awaiting = false
            }
        }
    }
    
    func deleteOutgoingFriendRequest(userID: String) {
        Task {
            do {
                awaiting = true
                try await nc.deleteOutgoingFriendRequest(userID: userID)
                updateData()
                withAnimation {
                    statusMessage = "Removed friend request."
                    showingStatus = true
                }
                awaiting = false
            } catch {
                statusMessage = error.localizedDescription
                showingStatus = true
                awaiting = false
            }
        }
    }
    
    func updateFriendRequest(status: String, userID: String) {
        Task {
            do {
                awaiting = true
                try await nc.updateIncomingFriendRequest(status: status, userID: userID)
                updateData()
                withAnimation {
                    statusMessage = status == "accepted" ? "Accepted friend request." : "Declined friend request."
                    showingStatus = true
                }
                awaiting = false
            } catch {
                statusMessage = error.localizedDescription
                showingStatus = true
                awaiting = false
            }
            
        }
    }
    
    func removeFriend(userID: String) {
        Task {
            do {
                awaiting = true
                try await nc.removeFriend(userID: userID)
                updateData()
                withAnimation {
                    statusMessage = "Removed friend :("
                    showingStatus = true
                }
                awaiting = false
            } catch {
                statusMessage = error.localizedDescription
                showingStatus = true
                awaiting = false
            }
        }
    }
    
    var body: some View {
        
        VStack {
            if (showingStatus) {
                Text(statusMessage)
                    .foregroundColor(.white)
                    .onAppear {
                        DispatchQueue.main.async {
                            Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { _ in
                                withAnimation {
                                    showingStatus = false
                                }
                            })
                        }
                    }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text(user.display_name)
                        .bucketNameStyle()
                        .foregroundColor(Color.white)
                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundColor(Color.white)
                            .frame(width: 15)
                        Text(user.username)
                            .bucketTextExternalStyle()
                    }
                    
                    HStack {
                        Image(systemName: "person.text.rectangle.fill")
                            .foregroundColor(Color.white)
                            .frame(width: 15)
                        Text(user.type == 0 ? "Player" : "Coach")
                            .bucketTextExternalStyle()
                    }
                }
                
                Spacer()
                
                if (awaiting) {
                    ProgressView()
                } else {
                    // Handle if the user is a friend
                    if (nc.userData.friends.firstIndex(of: user) != nil) {
                        Button(action: {
                            showRemoveFriendAlert = true
                        }, label: {
                            VStack {
                                Image(systemName: "person.crop.circle.fill.badge.checkmark")
                                Text("Friends")
                                    .friendStatusTextStyle()
                            }.friendStatusBackgroundStyle()
                        })
                    }
                    
                    // Handle if the user is not a friend but sent you a friend request
                    else if (nc.userData.incomingFriendRequests.firstIndex(of: user) != nil) {
                        HStack {
                            Button(action: {
                                updateFriendRequest(status: "accepted", userID: String(user.id))
                            }, label: {
                                VStack {
                                    Image(systemName: "person.fill.checkmark")
                                    Text("Accept")
                                        .friendStatusTextStyle()
                                }.friendStatusBackgroundStyle()
                            })
                            Button(action: {
                                updateFriendRequest(status: "declined", userID: String(user.id))
                            }, label: {
                                VStack {
                                    Image(systemName: "person.fill.xmark")
                                    Text("Decline")
                                        .friendStatusTextStyle()
                                }.friendStatusBackgroundStyle()
                            })
                        }
                    }
                    
                    // Handle if the user sent an outgoing friend request to this user
                    else if (nc.userData.outgoingFriendRequests.firstIndex(of: user) != nil) {
                        Button(action: {
                            deleteOutgoingFriendRequest(userID: String(user.id))
                        }, label: {
                            VStack {
                                Image(systemName: "person.wave.2.fill")
                                Text("Cancel")
                                    .friendStatusTextStyle()
                            }.friendStatusBackgroundStyle()
                            
                        })
                    }
                    
                    // Handle if the user has never interacted with this user (i.e., doesn't meet the above criteria); thus, they can only send a friend request
                    else {
                        Button(action: {
                            createFriendRequest(userID: String(user.id))
                        }, label: {
                            VStack {
                                Image(systemName: "person.crop.circle.fill.badge.plus")
                                Text("Add Friend")
                                    .friendStatusTextStyle()
                            }.friendStatusBackgroundStyle()
                        })
                    }
                }
                
                
            }.alert("Are you sure you want to remove \(user.display_name) (\(user.username)) as a friend?", isPresented: $showRemoveFriendAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Remove Friend", role: .destructive) {
                    removeFriend(userID: String(user.id))
                }
            }
        }.navigationLinkStyle()
        
    }
}

//struct UserCardView_Previews: PreviewProvider {
//    static var previews: some View {
//        UserCardView()
//    }
//}

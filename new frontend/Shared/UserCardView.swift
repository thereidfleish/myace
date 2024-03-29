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
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingStatus = false
    @State private var statusMessage = ""
    @State var user: SharedData
    @State private var showRemoveFriendAlert = false
    
    let reqOptions: [CourtshipType: String] = [.coach_req: "Coach", .student_req: "Student", .friend_req: "Friend"]
    
    func updateData() async {
        do {
            awaiting = true
            try await nc.getCourtships(user_id: "me", type: nil)
            try await nc.getCourtshipRequests(type: nil, dir: "in", users: nil)
            try await nc.getCourtshipRequests(type: nil, dir: "out", users: nil)
            awaiting = false
        } catch {
            print("Showing error: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
            awaiting = false
        }
    }
    
    func createCourtshipRequest(userID: String, type: CourtshipType) async {
        do {
            awaiting = true
            try await nc.createCourtshipRequest(userID: userID, type: type)
            await updateData()
            withAnimation {
                statusMessage = userID == String(nc.userData.shared.id) ? "We're sorry that you don't have any friends, but you still can't send a courtship request to yourself :(" : "Sent \(reqOptions[type] ?? "") request."
                showingStatus = true
            }
            awaiting = false
        } catch {
            print("Showing error: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
            awaiting = false
        }
    }
    
    func deleteOutgoingFriendRequest(userID: String) async {
        do {
            awaiting = true
            try await nc.deleteOutgoingCourtshipRequest(otherUserID: userID)
            await updateData()
            withAnimation {
                statusMessage = "Removed courtship request."
                showingStatus = true
            }
            awaiting = false
        } catch {
            print("Showing error: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
            awaiting = false
        }
    }
    
    func updateFriendRequest(status: String, userID: String) async {
        do {
            awaiting = true
            try await nc.updateIncomingCourtshipRequest(status: status, otherUserID: userID)
            await updateData()
            withAnimation {
                statusMessage = status == "accepted" ? "Accepted courtship request." : "Declined courtship request."
                showingStatus = true
            }
            awaiting = false
        } catch {
            print("Showing error: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
            awaiting = false
        }
    }
    
    func removeFriend(userID: String) async {
        do {
            awaiting = true
            try await nc.removeCourtship(otherUserID: userID)
            await updateData()
            withAnimation {
                statusMessage = "Removed courtship :("
                showingStatus = true
            }
            awaiting = false
        } catch {
            print("Showing error: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
            awaiting = false
        }
    }
    
    var body: some View {
        ZStack {
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
                    NavigationLink(destination: ProfileView(yourself: false, user: user))
                    {
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
                                Text(nc.userData.courtships.first(where :{$0.id == user.id})?.courtship?.type.rawValue.capitalized ?? reqOptions[(nc.userData.incomingCourtshipRequests.first(where :{$0.id == user.id})?.courtship?.type) ?? .undefined] ??
                                     reqOptions[(nc.userData.outgoingCourtshipRequests.first(where :{$0.id == user.id})?.courtship?.type) ?? .undefined] ??
                                     "")
                                    .bucketTextExternalStyle()
                            }
                        }
                        
                        Spacer()
                    }
                    
                    
                    if (awaiting) {
                        ProgressView()
                    }
                    else {
                        // Handle if the user is already a courtship
                        if (nc.userData.courtships.contains(where: {$0.id == user.id})) {
                            Button(action: {
                                showRemoveFriendAlert = true
                            }, label: {
                                VStack {
                                    Image(systemName: "person.crop.circle.fill.badge.checkmark")
                                    Text("Courtship")
                                        .friendStatusTextStyle()
                                }.friendStatusBackgroundStyle()
                            })
                        }
                        
                        // Handle if the user is not a courtship but sent you a courtship request
                        else if (nc.userData.incomingCourtshipRequests.contains(where: {$0.id == user.id})) {
                            HStack {
                                Button(action: {
                                    Task {
                                        await updateFriendRequest(status: "accept", userID: String(user.id))
                                    }
                                }, label: {
                                    VStack {
                                        Image(systemName: "person.fill.checkmark")
                                        Text("Accept")
                                            .friendStatusTextStyle()
                                    }.friendStatusBackgroundStyle()
                                })
                                Button(action: {
                                    Task {
                                        await updateFriendRequest(status: "decline", userID: String(user.id))
                                    }
                                    
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
                        else if (nc.userData.outgoingCourtshipRequests.contains(where: {$0.id == user.id})) {
                            Button(action: {
                                Task {
                                    await deleteOutgoingFriendRequest(userID: String(user.id))
                                }
                                
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
                            Menu {
                                Button {
                                    Task {
                                        await createCourtshipRequest(userID: String(user.id), type: .friend_req)
                                    }
                                    
                                } label: {
                                    Label("Add Friend", systemImage: "face.smiling.fill")
                                }
                                
                                Button {
                                    Task {
                                        await createCourtshipRequest(userID: String(user.id), type: .student_req)
                                    }
                                    
                                } label: {
                                    Label("Add Student", systemImage: "graduationcap.fill")
                                }
                                
                                Button {
                                    Task {
                                        await createCourtshipRequest(userID: String(user.id), type: .coach_req)
                                    }
                                    
                                } label: {
                                    Label("Add Coach", systemImage: "person.text.rectangle.fill")
                                }
                                
                            } label: {
                                VStack {
                                    Image(systemName: "person.crop.circle.fill.badge.plus")
                                    Text("Add Courtship")
                                        .friendStatusTextStyle()
                                }.friendStatusBackgroundStyle()
                            }
                            .padding(.leading)
                        }
                    }
                    
                    
                }.alert("Are you sure you want to remove \(user.display_name) (\(user.username)) as a courtship?", isPresented: $showRemoveFriendAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Remove Courtship", role: .destructive) {
                        Task {
                            await removeFriend(userID: String(user.id))
                        }
                        
                    }
                }
            }.navigationLinkStyle()
            if showingError {
                Message(title: "Error", message: errorMessage, style: .error, isPresented: $showingError, view: nil)
            }
        }
        
    }
}

//struct UserCardView_Previews: PreviewProvider {
//    static var previews: some View {
//        UserCardView()
//    }
//}

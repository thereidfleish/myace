//
//  NewUserOnboardingView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 1/19/22.
//

import SwiftUI

struct ProfileSettingsView: View {
    @EnvironmentObject private var nc: NetworkController
    @State private var username = ""
    @State private var displayName = ""
    @State private var biography = ""
    @State private var awaiting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingNewBucketView = false
    var isNewUser: Bool
    @State private var displaySaveMessage = false
    @State private var saveMessage = ""
    
    func updateUser() async {
            do {
                awaiting = true
                if(nc.userData.shared.username != username) {
                    let (valid, available) = try await nc.checkUsername(userName: username)
                    if(!valid || !available) {
                        saveMessage = "\(!valid ? "Username is invalid." : "")\(!available ? "Username is not available." : "")\nPlease try a different username."
                    } else {
                        try await nc.updateCurrentUser(username: username, displayName: displayName, biography: biography)
                        saveMessage = "Changes Saved Successfully!"
                        nc.newUser = false
                    }
                }
                else {
                    try await nc.updateCurrentUser(username: nil, displayName: displayName, biography: biography)
                    saveMessage = "Changes Saved Successfully!"
                    nc.newUser = false
                }
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
                Text(isNewUser ? "Welcome to AI Tennis Coach!  We've created a username for you below.  Since your username is how friends will find you, feel free to change it below." : "Username")
                    .bucketTextInternalStyle()
                    .onAppear(perform: {
                        username = nc.userData.shared.username
                        displayName = nc.userData.shared.display_name
                        biography = nc.userData.shared.biography
                        if(isNewUser) {
                            nc.userData.buckets = []
                        }
                    })
                TextField("Edit Username", text: $username)
                    .textFieldStyle()
                
                Text(isNewUser ? "We've also created a display name for you below.  Since this is how friends will refer to you, feel free to change it below.": "Display Name")
                    .padding(.top, 20)
                    .bucketTextInternalStyle()
//                    .onAppear(perform: {
//                        //username = nc.userData.shared.username
//                    })
                
                TextField("Edit Display Name", text: $displayName)
                    .textFieldStyle()
                
                
                Text(isNewUser ? "Tell us a little about yourself in your profile bio.": "Bio")
                    .padding(.top, 20)
                    .bucketTextInternalStyle()
                
                TextField("Edit Bio", text: $biography)
                    .textFieldStyle()
                
                if(isNewUser) {
                    Text("Before getting started, you must create at least one bucket. Buckets are where you store videos.")
                        .padding(.top, 20)
                        .bucketTextInternalStyle()
                    Button(action: {
                        showingNewBucketView.toggle()
                    }, label: {
                        Text("Create New Bucket")
                            .buttonStyle()
                    })
                    ForEach(nc.userData.buckets) { bucket in
                        VStack(alignment: .leading) {
                            Text(bucket.name)
                        }
                    }
                }
                
                Spacer()
                
                if (displaySaveMessage) {
                    Text(saveMessage)
                        .padding(.top, 20)
                        .bucketTextInternalStyle()
                        .onAppear {
                            DispatchQueue.main.async {
                                Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { _ in
                                    withAnimation {
                                        displaySaveMessage = false
                                    }
                                })
                            }
                        }
                }
                
                Button(action: {
                    Task {
                        await updateUser()
                        //if(!isNewUser) {
                            withAnimation {
                                displaySaveMessage = true;
                            }
                        //}
                    }
                    
                }, label: {
                    Text(isNewUser ? "Continue" : "Save")
                        .buttonStyle()
                }).disabled(isNewUser && nc.userData.buckets.count == 0)
                    .opacity(isNewUser && nc.userData.buckets.count == 0 ? 0.5 : 1)
                
                
            }.padding(.horizontal)
                .sheet(isPresented: $showingNewBucketView) {
                    NewBucketView()
                    
                }
        
        
        
    }
}

//struct NewUserOnboardingView_Previews: PreviewProvider {
//    static var previews: some View {
//        NewUserOnboardingView()
//    }
//}

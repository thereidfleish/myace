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
    @State private var userNameMessage = ""
    @State private var userNameValidAndAvailable = true
    @Binding var showProfileSettingsView: Bool
    
    func checkValidAndAvailable() async {
        do {
            let (valid, available) = try await nc.checkUsername(userName: username.replacingOccurrences(of: " ", with: "").lowercased())
            if(!valid || !available) {
                userNameMessage = "\(!valid ? "Username is invalid. Must contain 4-16 characters. At least one letter. No special characters except . and _" : "")\(!available ? "Username is not available." : "")\nPlease try a different username."
                userNameValidAndAvailable = false
            } else {
                userNameMessage = "Username is available!"
                userNameValidAndAvailable = true
            }
        }
        catch {
            print("Showing error: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
            awaiting = false
        }
    }
    
    func updateUser() async {
            do {
                awaiting = true
                try await nc.updateCurrentUser(username: username.replacingOccurrences(of: " ", with: "").lowercased(), displayName: displayName, biography: biography)
                showProfileSettingsView = false
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
            ScrollView {
                VStack(alignment: .leading) {
                    Text(isNewUser ? "Welcome to MyAce!  We've created a username for you below.  Since your username is how friends will find you, feel free to change it below." : "Username")
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
                        .onChange(of: username) { newValue in
                            Task {
                                await checkValidAndAvailable()
                            }
                        }
                    
                    if (userNameMessage != "") {
                        Text(userNameMessage)
                            .smallestSubsectionStyle()
                    }
                    
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
                    })
                    
                    
                }.padding(.horizontal)
                    
            }
            if showingError {
                Message(title: "Error", message: errorMessage, style: .error, isPresented: $showingError, view: nil)
            }
        }
        
        
    }
}

//struct NewUserOnboardingView_Previews: PreviewProvider {
//    static var previews: some View {
//        NewUserOnboardingView()
//    }
//}

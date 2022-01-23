//
//  ProfileView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 1/3/22.
//

import SwiftUI
import GoogleSignIn

struct ProfileView: View {
    @EnvironmentObject private var nc: NetworkController
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @AppStorage("type") private var typeSelection = -1
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var awaiting = false
    @State private var presentingSettingsSheet = false
    
    var yourself: Bool
    var user: Friend
    
    func initialize() {
        Task {
            do {
                awaiting = true
                try await nc.getFriends()
                awaiting = false
                print("DONE!")
            } catch {
                print(error)
                errorMessage = error.localizedDescription
                showingError = true
                awaiting = false
            }
            
            print(nc.userData.friends)
        }
        
    }
    var body: some View {
        NavigationView {
            if (awaiting) {
                ProgressView()
            } else if (showingError) {
                Text(UserData.computeErrorMessage(errorMessage: errorMessage)).padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading) {
                        
                        Text(yourself ? (nc.userData.shared.type == 0 ? "Player" : "Coach") : (user.type == 0 ? "Player" : "Coach"))
                            .profileInfoStyle()
                        
                        HStack {
                            AsyncImage(url: nc.userData.profilePic) { image in
                                image.resizable()
                            } placeholder: {
                                ProgressView()
                            }
                            .frame(width: 128, height: 128)
                            .clipShape(Circle())
                            
                            Spacer()
                            
                            HStack {
                                VStack {
                                    Text("42")
                                        .videoInfoStyle()
                                        .foregroundColor(Color.green)
                                    Text("Videos")
                                        .profileTextStyle()
                                }
                                
                                Spacer()
                                NavigationLink(destination: FriendsView().navigationTitle("Friends").navigationBarTitleDisplayMode(.inline)) {
                                    
                                    
                                    VStack {
                                        Text("\(nc.userData.friends.count)")
                                            .profileInfoStyle()
                                        Text("Friends")
                                            .profileTextStyle()
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                        }
                        
                        
                        Text(yourself ? nc.userData.shared.display_name : user.display_name)
                            .profileInfoStyle()
                        
                        Text("The users will be able to write a description of themselves here, like on Instagram.")
                            .profileTextStyle()
                        
                        
                        Spacer()
                        
                        Text("\(nc.userData.shared.email) | User ID: \(yourself ? nc.userData.shared.id : user.id)")
                            .font(.footnote)
                            .foregroundColor(Color.green)
                        
                        
                    }.padding(.horizontal)
                    
                    
                }.navigationTitle(yourself ? nc.userData.shared.username : user.username)
                    .navigationBarItems(leading: Button(action: {
                        if (yourself) {
                            GIDSignIn.sharedInstance.signOut()
                            nc.userData.shared.type = -1
                            typeSelection = -1
                        } else {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }, label: {
                        Text(yourself ? "Log Out" : "< Back")
                            .foregroundColor(yourself ? Color.red : .accentColor)
                                .fontWeight(.bold)
                    }),
                    trailing:
                        Button(action: {
                            presentingSettingsSheet = true
                        }, label: {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(Color.green)
                        }))
            }
        }
        .sheet(isPresented: $presentingSettingsSheet, onDismiss: {initialize()}) {
            SettingsView()
        }
    }
}

//struct ProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//        ProfileView()
//    }
//}

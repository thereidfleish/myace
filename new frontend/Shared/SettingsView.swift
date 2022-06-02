//
//  SettingsView.swift
//  AI Tennis Coach
//
//  Created by AndrewC on 1/23/22.
//

import SwiftUI
import GoogleSignIn


struct SettingsView: View {
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    @EnvironmentObject private var nc: NetworkController
    @State private var showDeleteAccount: Bool = false
    
    func deleteCurrentUser()  {
        Task {
            do {
                try await nc.deleteCurrentUser()
                GIDSignIn.sharedInstance.signOut()
                print("logged out")
                nc.clearUserData()
                self.mode.wrappedValue.dismiss()
            } catch {
                print(error)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("General")
                        .bucketNameStyle()
                        .foregroundColor(Color.green)
                        .padding(.horizontal)
                    NavigationLink(destination: ProfileSettingsView(isNewUser: false)) {
                        HStack {
                            Text("Edit Profile Info")
                                .bucketNameStyle()
                                .foregroundColor(Color.white)
                            Spacer()
                            Image(systemName: "chevron.right.square.fill")
                                .resizable()
                                .scaledToFill()
                                .foregroundColor(Color.white)
                                .frame(width: 20, height: 20)
                        }
                        .navigationLinkStyle()
                    }
                    if (showDeleteAccount) {
                        HStack {
                            Text("Are you sure you want to delete your account?  This cannot be undone!")
                                .foregroundColor(.red)
                            Button(action: {
                                deleteCurrentUser()
                            }, label: {
                                Text("Permanently Delete Account")
                                    .foregroundColor(.red)
                                    .fontWeight(.bold)
                            })
                        }.padding(.horizontal)
                    }
                    Button(action: {withAnimation {showDeleteAccount = true}}) {
                        HStack {
                            Text("Delete Account")
                                .bucketNameStyle()
                                .foregroundColor(Color.white)
                            Spacer()
                            Image(systemName: "trash.fill")
                                .resizable()
                                .scaledToFill()
                                .foregroundColor(Color.white)
                                .frame(width: 20, height: 20)
                        }
                            .padding()
                            .background(.red)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing:
                                    Button(action: {
                self.mode.wrappedValue.dismiss()
            }, label: {
                Text("Done")
                    .foregroundColor(.green)
            })
                                
            )
        }
        
        
        
    }
}



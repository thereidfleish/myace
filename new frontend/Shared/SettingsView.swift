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
    @State private var showProfileSettingsView = true
    @State private var showingError = false
    @State private var showingSuccess = false
    @State private var errorMessage = ""
    @State private var awaiting = true
    @State private var showAboutPage = false
    @State private var showingOnboarding = true
    
    func deleteCurrentUser()  {
        Task {
            do {
                try await nc.deleteCurrentUser()
                showingSuccess = true
                
                DispatchQueue.main.async {
                    Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { _ in
                        nc.logOut()
                        self.mode.wrappedValue.dismiss()
                    })
                }
            } catch {
                print("Showing error: \(error)")
                errorMessage = error.localizedDescription
                showingError = true
                awaiting = false
            }
        }
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading) {
                        Button(action: {
                            UIApplication.shared.open(URL(string: "https://docs.google.com/forms/d/e/1FAIpQLSf9aY2-RUsSVp3pIBqvP6dmdqVJcC9Z6LOygBFlWmEY_f213Q/viewform?usp=sf_link")!)
                        }) {
                            HStack {
                                Text("Give Feedback")
                                    .bucketNameStyle()
                                    .foregroundColor(Color.white)
                                Spacer()
                                Image(systemName: "text.bubble.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundColor(Color.white)
                                    .frame(width: 20, height: 20)
                            }
                            .padding()
                            .background(.green)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                        }
                        NavigationLink(destination: OnboardingView(showProfileSettingsView: false, hideLastPageCuzAndrewIsAnnoying: true)) {
                            HStack {
                                Text("Show Onboarding")
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
                        Text("Account")
                            .bucketNameStyle()
                            .foregroundColor(Color.green)
                        NavigationLink(destination: ProfileSettingsView(isNewUser: false, showProfileSettingsView: $showProfileSettingsView).navigationTitle("Edit Profile")) {
                            HStack {
                                Text("Edit Profile")
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
                        Button(action: {withAnimation {showDeleteAccount.toggle()}}) {
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
                    .padding(.horizontal)
                }
                .navigationTitle("Settings")
                .navigationBarItems(leading: Button(action: {
                    showAboutPage.toggle()
                }, label: {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(Color.green)
                }), trailing:
                                        Button(action: {
                    self.mode.wrappedValue.dismiss()
                }, label: {
                    Text("Done")
                        .foregroundColor(.green)
                })
                                    
                )
                .sheet(isPresented: $showAboutPage) {
                    Info()
                }
            }
            if showingError {
                Message(title: "Error", message: errorMessage, style: .error, isPresented: $showingError, view: nil)
            }
            if showingSuccess {
                Message(title: "Successfully deleted user!", message: "", style: .success, isPresented: $showingSuccess, view: nil)
            }
        }
        
    }
}



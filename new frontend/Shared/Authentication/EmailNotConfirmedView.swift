//
//  EmailNotConfirmedView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 6/11/22.
//

import SwiftUI

struct EmailNotConfirmedView: View {
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    @EnvironmentObject private var nc: NetworkController
    @State private var awaiting = false
    @State private var showingError = false
    @State private var deleteUserSuccessful = false
    @State private var errorMessage = ""
    @State private var resendSuccessful = false
    
    @State private var showDeleteAccount: Bool = false
    
    func resendConfirmationEmail() async {
        do {
            awaiting = true
            try await nc.resendConfirmationEmail()
            resendSuccessful = true
            awaiting = false
        } catch {
            print("Showing error: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
            awaiting = false
        }
    }
    
    func updateUser() async {
        do {
            awaiting = true
            try await nc.updateCurrentUser(username: nil, displayName: nil, biography: nil)
            awaiting = false
        } catch {
            print("Showing error: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
            awaiting = false
        }
    }
    
    func deleteCurrentUser()  {
        Task {
            do {
                try await nc.deleteCurrentUser()
                deleteUserSuccessful = true
                
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
                        Text("You must verify your email (\(nc.userData.shared.email ?? "")) before continuing.")
                            .bucketTextInternalStyle()
                        
                        Button(action: {
                            Task {
                                await resendConfirmationEmail()
                            }
                            
                        }, label: {
                            Text("Resend Confirmation Email")
                                .buttonStyle()
                        })
                        Button(action: {
                            nc.logOut()
                        }, label: {
                            Text("Log Out")
                                .buttonStyle()
                        })
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
                                    .padding(.vertical, 15)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.red)
                                    .cornerRadius(10)
                                    .foregroundColor(.white)
                            }

                        }
                        
                    }.padding(.horizontal)
     
                }
                .padding(.horizontal)
                    .navigationBarTitle("Email Not Confirmed", displayMode: .inline)
                    .navigationBarItems(trailing: Refresher().refreshable {
                        await updateUser()
                    })
                
            }

            if resendSuccessful {
                Message(title: "Email Resent", message: "The confirmation email has been resent to \(nc.userData.shared.email ?? "").", style: .success, isPresented: $resendSuccessful, view: nil)
            }
            if deleteUserSuccessful {
                Message(title: "Successfully deleted user!", message: "", style: .success, isPresented: $deleteUserSuccessful, view: nil)
            }
            if showingError {
                Message(title: "Error", message: errorMessage, style: .error, isPresented: $showingError, view: nil)
            }
        }
            
    }
}


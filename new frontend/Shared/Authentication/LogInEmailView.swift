//
//  LogInEmailView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 6/4/22.
//

import SwiftUI

struct LogInEmailView: View {
    @EnvironmentObject private var nc: NetworkController
    @State private var email = ""
    @State private var password = ""
    
    @State private var awaiting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var displayLoginMessage = false
    @State private var loginMessage = ""
    
    func loginWithEmail() async {
            do {
                awaiting = true
                //try await nc.updateCurrentUser(username: nil, displayName: displayName, biography: biography)
                loginMessage = "Username or password is incorrect."
                loginMessage = "Your email has not been verified. Please check your inbox for a verification email. Would you like to resend it?"
            } catch {
                print(error)
                errorMessage = error.localizedDescription
                showingError = true
                awaiting = false
            }
    }
    
    var body: some View {
        ScrollView {
            VStack {
                Text("Email")
                    .padding(.top, 20)
                    .bucketTextInternalStyle()
                TextField("john@example.com", text: $email)
                    .textFieldStyle()
                Text("Password")
                    .padding(.top, 20)
                    .bucketTextInternalStyle()
                SecureField("Password", text: $password)
                    .textFieldStyle()
                Spacer()
                if (displayLoginMessage) {
                    Text(loginMessage)
                        .padding(.top, 20)
                        .bucketTextInternalStyle()
                        .onAppear {
                            DispatchQueue.main.async {
                                Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { _ in
                                    withAnimation {
                                        displayLoginMessage = false
                                    }
                                })
                            }
                        }
                }
                Button(action: {
                    Task {
                        await loginWithEmail()
                            withAnimation {
                                displayLoginMessage = true;
                            }
                    }
                    
                }, label: {
                    Text("Log In")
                        .buttonStyle()
                }).disabled(email == "" || password == "")
                    .opacity(email == "" || password == "" ? 0.5 : 1)
                
                
                    .navigationTitle("Log In")
            }.padding(.horizontal)
        }
    }
}


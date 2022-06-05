//
//  RegisterEmailView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 6/4/22.
//

import SwiftUI

struct RegisterEmailView: View {
    @EnvironmentObject private var nc: NetworkController
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var biography = ""
    
    
    @State private var awaiting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var registerMessage = ""
    @State private var displayRegisterMessage = false
    @State private var loginMessage = ""
    @State private var userNameMessage = ""
    @State private var userNameValidAndAvailable = true
    @State private var registrationSuccessful = false
    
    func checkValidAndAvailable() async {
        do {
            let (valid, available) = try await nc.checkUsername(userName: username)
            if(!valid || !available) {
                userNameMessage = "\(!valid ? "Username is invalid. Must contain 4-16 characters. At least one letter. No special characters except . and _" : "")\(!available ? "Username is not available." : "")\nPlease try a different username."
                userNameValidAndAvailable = false
            } else {
                userNameMessage = "Username is available!"
                userNameValidAndAvailable = true
            }
        }
        catch {
            print(error)
            errorMessage = error.localizedDescription
            showingError = true
            awaiting = false
        }
    }
    
    func registerWithEmail() async {
            do {
                awaiting = true
                try await nc.registerWithEmail(username: username, display_name: displayName, biography: biography, email: email, password: password)
                registerMessage = "Registration successful! A confirmation email has been sent to \(email)."
                registrationSuccessful = true
//                registerMessage = "Your email has not been verified. Please check your inbox for a verification email. Would you like to resend it?"
                awaiting = false
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
                Group {
                    Text("Email")
                        .bucketTextInternalStyle()
                    TextField("john@example.com", text: $email)
                        .textFieldStyle()
                    Text("Username")
                        .bucketTextInternalStyle()
                    TextField("Create Username", text: $username)
                        .textFieldStyle()
                        .onChange(of: username) { newValue in
                        Task {
                            await checkValidAndAvailable()
                        }
                    }
                    
                    Text(userNameMessage)
                        .bucketTextInternalStyle()
                    
                    Text("Password")
                        .bucketTextInternalStyle()
                    SecureField("Create Password", text: $password)
                        .textFieldStyle()
                    
                    Text(password == confirmPassword ? (password == "" ? "Please enter a password" : "Passwords match!") : "Passwords don't match")
                        .padding(.top, 20)
                        .bucketTextInternalStyle()
                    
                    Text("Confirm Password")
                        .bucketTextInternalStyle()
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle()
                }
                
                
                
                Text("Display Name")
                    .padding(.top, 20)
                    .bucketTextInternalStyle()
                
                TextField("Create Display Name", text: $displayName)
                    .textFieldStyle()
                
                
                Text("Bio")
                    .padding(.top, 20)
                    .bucketTextInternalStyle()
                
                TextField("Create Bio", text: $biography)
                    .textFieldStyle()
                
                if (displayRegisterMessage) {
                    Text(registerMessage)
                        .padding(.top, 20)
                        .bucketTextInternalStyle()
                        .onAppear {
                            DispatchQueue.main.async {
                                Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { _ in
                                    withAnimation {
                                        displayRegisterMessage = false
                                    }
                                    if(registrationSuccessful) {
                                        dismiss()
                                    }
                                })
                            }
                        }
                }
                
                Button(action: {
                    Task {
                        await registerWithEmail()
                            withAnimation {
                                displayRegisterMessage = true;
                            }
                    }
                    
                }, label: {
                    Text("Register")
                        .buttonStyle()
                }).disabled(password != confirmPassword || !userNameValidAndAvailable || password == "" || email == "")
                    .opacity(password != confirmPassword || !userNameValidAndAvailable || password == "" || email == "" ? 0.5 : 1)
                
                    .navigationTitle("Register")
            }.padding(.horizontal)
        }
    }
}


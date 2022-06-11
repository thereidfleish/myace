//
//  RegisterEmailView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 6/4/22.
//

import SwiftUI

struct RegisterEmailView: View {
    @EnvironmentObject private var nc: NetworkController
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    
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
    
    func registerWithEmail() async {
        do {
            awaiting = true
            try await nc.registerWithEmail(username: username, display_name: displayName, biography: biography, email: email, password: password)
            registrationSuccessful = true
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
                    Group {
                        Text("Email")
                            .bucketTextInternalStyle()
                        
                        TextField("john@example.com", text: $email)
                            .textFieldStyle()
                        
                        Text("Password")
                            .padding(.top)
                            .bucketTextInternalStyle()
                        
                        SecureField("Create Password", text: $password)
                            .textFieldStyle()
                        
                        Text("Confirm Password")
                            .padding(.top)
                            .bucketTextInternalStyle()
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle()
                        
                        if (password != "") {
                            Text(password == "" ? "" : (password == confirmPassword ? "Passwords match!" : "Passwords don't match."))
                                .smallestSubsectionStyle()
                        }
                        
                        Text("Username")
                            .padding(.top)
                            .bucketTextInternalStyle()
                        
                        TextField("Create Username", text: $username)
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
                        
                        
                        
                    }
                    
                    
                    Text("Display Name")
                        .padding(.top)
                        .bucketTextInternalStyle()
                    
                    TextField("What would you like to be called?", text: $displayName)
                        .textFieldStyle()
                    
                    
                    Text("Bio")
                        .padding(.top)
                        .bucketTextInternalStyle()
                    
                    TextField("Type something about yourself", text: $biography)
                        .textFieldStyle()
                    
                    if (displayRegisterMessage) {
                        Text(registerMessage)
                            .smallestSubsectionStyle()
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
                    })
                    .padding(.top)
                    .disabled(password != confirmPassword || !userNameValidAndAvailable || password == "" || email == "")
                    .opacity(password != confirmPassword || !userNameValidAndAvailable || password == "" || email == "" ? 0.5 : 1)
                    
                    .navigationTitle("Register")
                }.padding(.horizontal)
            }
            
            if showingError {
                Message(title: "Error", message: errorMessage, style: .error, isPresented: $showingError, view: nil)
            }
            
            if registrationSuccessful {
                Message(title: "Account Created", message: "Registration successful! A confirmation email has been sent to \(email).", style: .success, isPresented: $registrationSuccessful, view:
                            AnyView(NavigationLink(destination: EmailNotConfirmedView(), label: {Text("Continue").messageButtonStyle()}))
                )
            }
        }
    }
}


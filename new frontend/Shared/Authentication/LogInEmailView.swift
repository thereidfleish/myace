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
//    @State private var loginMessage = ""
        
    func loginWithEmail() async {
        do {
            try await nc.login(method: "password", email: email, password: password, token: nil)
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
                    Text("Email")
                        .bucketTextInternalStyle()
                    
                    TextField("john@example.com", text: $email)
                        .textFieldStyle()
                    
                    Text("Password")
                        .padding(.top)
                        .bucketTextInternalStyle()
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle()
                    
                    NavigationLink(destination: ForgotPasswordView()) {
                        Text("Forgot Password?")
                            .bold()
                            .foregroundColor(.green)
                    }
                    
                    
                    if (!awaiting) {
                        Button(action: {
                            Task {
                                awaiting = true
                                await loginWithEmail()
                            }
                            
                        }, label: {
                            Text("Log In")
                                .buttonStyle()
                        })
                        .padding(.top)
                        .disabled(email == "" || password == "")
                            .opacity(email == "" || password == "" ? 0.5 : 1)
                    }
                    
                    if (awaiting) {
                        ProgressView()
                    }
                    
                    Text("Don't have an account yet?")
                        .bucketTextInternalStyle()
                        .padding(.top)
                    
                    NavigationLink(destination: RegisterEmailView()) {
                        Text("Register with Email")
                            .buttonStyle()
                    }
                    
                    
                    
                    
                    
                    
                    .navigationTitle("Log In")
                }.padding(.horizontal)
            }
            if showingError {
                Message(title: "Error", message: errorMessage, style: .error, isPresented: $showingError, view: nil)
            }
        }
    }
}


//
//  RegisterEmailView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 6/4/22.
//

import SwiftUI

struct ForgotPasswordView: View {
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
                    Text("Email")
                        .bucketTextInternalStyle()
                    TextField("john@example.com", text: $email)
                        .textFieldStyle()
                    
                    Button(action: {
                        Task {
                            await registerWithEmail()
                            withAnimation {
                                displayRegisterMessage = true;
                            }
                        }
                        
                    }, label: {
                        Text("Send password reset email")
                            .buttonStyle()
                    })
                    .padding(.top)
                    .disabled(password != confirmPassword || !userNameValidAndAvailable || password == "" || email == "")
                    .opacity(password != confirmPassword || !userNameValidAndAvailable || password == "" || email == "" ? 0.5 : 1)
                    
                    .navigationTitle("Reset Password")
                }.padding(.horizontal)
            }
            
            if showingError {
                Message(title: "Error", message: errorMessage, style: .error, isPresented: $showingError, view: nil)
            }
            
            if registrationSuccessful {
                Message(title: "Email Sent", message: "If the email provided is associated with an account that uses email login, a password reset email has been sent to \(email).", style: .success, isPresented: $registrationSuccessful, view:
                            AnyView(Button(action: {self.mode.wrappedValue.dismiss()}, label: {Text("Continue").messageButtonStyle()}))
                )
            }
        }
    }
}


//
//  ForgotPasswordView.swift
//  AI Tennis Coach
//
//  Created by Andrew Chen on 6/10/22.
//

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject private var nc: NetworkController
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    @State private var email = ""
    
    @State private var awaiting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    @State private var resetPasswordEmailSent = false
    
    func registerWithEmail() async {
        do {
            awaiting = true
            try await nc.forgotPassword(email: email)
            resetPasswordEmailSent = true
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
                    Text("Please enter the email associated with your account. You can only reset your password if your email is associated with an account that uses email login (i.e. not Google or Apple sign-in).")
                        .bucketTextInternalStyle()
                    
                    Text("Email")
                        .bucketTextInternalStyle()
                        .padding(.top)
                    TextField("john@example.com", text: $email)
                        .textFieldStyle()
                    
                    Button(action: {
                        Task {
                            await registerWithEmail()
                        }
                        
                    }, label: {
                        Text("Send password reset email")
                            .buttonStyle()
                    })
                    .padding(.top)
                    
                    .navigationTitle("Reset Password")
                }.padding(.horizontal)
            }
            
            if showingError {
                Message(title: "Error", message: errorMessage, style: .error, isPresented: $showingError, view: nil)
            }
            
            if resetPasswordEmailSent {
                Message(title: "Email Sent", message: "If the email provided is associated with an account that uses email login, a password reset email has been sent to \(email).", style: .success, isPresented: $resetPasswordEmailSent, view:
                            AnyView(Button(action: {self.mode.wrappedValue.dismiss()}, label: {Text("Continue").messageButtonStyle()}))
                )
            }
        }
    }
}


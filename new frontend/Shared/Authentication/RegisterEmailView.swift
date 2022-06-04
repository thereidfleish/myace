//
//  RegisterEmailView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 6/4/22.
//

import SwiftUI

struct RegisterEmailView: View {
    @State private var email = ""
    @State private var username = ""
    @State private var displayName = ""
    @State private var biography = ""
    var body: some View {
        ScrollView {
            VStack {
                Text("Email")
                    .bucketTextInternalStyle()
                TextField("john@example.com", text: $email)
                    .textFieldStyle()
                Text("Username")
                    .bucketTextInternalStyle()
                TextField("Create Username", text: $username)
                    .textFieldStyle()
                
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
                
                    .navigationTitle("Register")
            }.padding(.horizontal)
        }
    }
}


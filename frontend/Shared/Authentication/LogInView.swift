//
//  LogInView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/27/21.
//

import SwiftUI

struct LogInView: View {
    @EnvironmentObject private var networkController: NetworkController
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack {
            Text("AI Tennis Coach")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.green)
            
            Button(action: {
                Task {
                    do {
                        try await networkController.authenticate(token: "test", type: 0)
                    } catch {
                        print(error)
                        errorMessage = error.localizedDescription
                        showingError.toggle()
                    }
                    networkController.awaiting = false
                    print(networkController.userData.shared)
                }
                
                
            }, label: {
                if (!networkController.awaiting) {
                    Text("Sign In With Google")
                        .padding(.vertical, 15)
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                        .foregroundColor(.white)
                } else {
                    ProgressView()
                }
            })
            
            Button(action: {
                networkController.userData.shared.type = 0
            }, label: {
                Text("fake a student view for now lol")
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
                    .foregroundColor(.white)
            })
            
            Button(action: {
                networkController.userData.shared.type = 1
            }, label: {
                Text("fake a coach view for now lol")
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
                    .foregroundColor(.white)
            })
            
            
        }.padding(.horizontal)
            .alert(isPresented: $showingError) {
            Alert(title: Text("Error"), message: Text("Error: \(errorMessage).  \(errorMessage.contains("0") ? "JSON Encode Error" : "JSON Decode Error").  Please check your internet connection, or try again later."), dismissButton: .default(Text("OK")))
        }
        
    }
}

struct LogInView_Previews: PreviewProvider {
    static var previews: some View {
        LogInView()
    }
}

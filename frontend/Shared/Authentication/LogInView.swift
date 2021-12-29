//
//  LogInView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/27/21.
//

import SwiftUI

struct LogInView: View {
    @EnvironmentObject private var networkController: NetworkController
    
    var body: some View {
        VStack {
            Text("AI Tennis Coach")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.green)
            
            Button(action: {
                Task {
                    await networkController.authenticate(token: "test", type: 0)
                    print(networkController.userData.shared)
                }
                
                
            }, label: {
                Text("Sign In With Google")
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
                    .foregroundColor(.white)
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
        
    }
}

struct LogInView_Previews: PreviewProvider {
    static var previews: some View {
        LogInView()
    }
}

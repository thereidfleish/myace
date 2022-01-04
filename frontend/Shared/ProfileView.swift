//
//  ProfileView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 1/3/22.
//

import SwiftUI
import GoogleSignIn

struct ProfileView: View {
    @EnvironmentObject private var nc: NetworkController
    @AppStorage("type") private var typeSelection = -1
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    AsyncImage(url: nc.userData.profilePic) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(width: 128, height: 128)
                    .clipShape(RoundedRectangle(cornerRadius: 25))
                    
                    Text(nc.userData.shared.display_name)
                        .font(.title)
                        .fontWeight(.heavy)
                        .foregroundColor(Color.green)
                    
                    Text(nc.userData.shared.type == 0 ? "Player" : "Coach")
                        .font(.headline)
                        .fontWeight(.heavy)
                        .foregroundColor(Color.green)
                    
                    Spacer()
                    
                    Text("\(nc.userData.shared.email) | User ID: \(nc.userData.shared.id)")
                        .font(.footnote)
                        .foregroundColor(Color.green)

                }.padding(.horizontal)
                
                
            }.navigationTitle("My Profile")
                .navigationBarItems(leading: Button(action: {
                    GIDSignIn.sharedInstance.signOut()
                    nc.userData.shared.type = -1
                    typeSelection = -1
                }, label: {
                    Text("Log Out")
                        .foregroundColor(Color.red)
                        .fontWeight(.bold)
                }))
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}

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
                VStack(alignment: .leading) {
                    
                    Text(nc.userData.shared.type == 0 ? "Player" : "Coach")
                        .font(.headline)
                        .fontWeight(.heavy)
                        .foregroundColor(Color.green)
                    
                    HStack {
                        AsyncImage(url: nc.userData.profilePic) { image in
                            image.resizable()
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: 128, height: 128)
                        .clipShape(Circle())
                        
                        Spacer()
                        
                        HStack {
                            VStack {
                                Text("42")
                                    .font(.headline)
                                    .fontWeight(.heavy)
                                    .foregroundColor(Color.green)
                                Text("Videos")
                                    .font(.subheadline)
                                    .foregroundColor(Color.green)
                            }
                            
                            Spacer()
                            
                            VStack {
                                Text("69")
                                    .font(.headline)
                                    .fontWeight(.heavy)
                                    .foregroundColor(Color.green)
                                Text("Friends")
                                    .font(.subheadline)
                                    .foregroundColor(Color.green)
                            }
                        }
                        .padding(.horizontal)
                        
                    }
                    
                    
                    Text(nc.userData.shared.display_name)
                        .font(.headline)
                        .fontWeight(.heavy)
                        .foregroundColor(Color.green)
                    
                    Text("The users will be able to write a description of themselves here, like on Instagram.")
                        .font(.subheadline)
                        .foregroundColor(Color.green)
                    
                    
                    Spacer()
                    
                    Text("\(nc.userData.shared.email) | User ID: \(nc.userData.shared.id)")
                        .font(.footnote)
                        .foregroundColor(Color.green)
                    
                }.padding(.horizontal)
                
                
            }.navigationTitle("thereidfleish")
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

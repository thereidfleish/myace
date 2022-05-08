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
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    //@AppStorage("type") private var typeSelection = -1
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var awaiting = false
    @State private var presentingSettingsSheet = false
    
    var yourself: Bool
    var user: SharedData?
    
    func initialize() {
        Task {
            do {
                awaiting = true
                try await nc.getCourtships(type: nil, users: nil)
                awaiting = false
                print("DONE!")
            } catch {
                print(error)
                errorMessage = error.localizedDescription
                showingError = true
                awaiting = false
            }
            
            print(nc.userData.courtships)
        }
        
    }
    var body: some View {
        NavigationView {
            if (awaiting) {
                ProgressView()
            } else if (showingError) {
                Text(Helper.computeErrorMessage(errorMessage: errorMessage)).padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading) {
                        
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
                                        .videoInfoStyle()
                                        .foregroundColor(Color.green)
                                    Text("Videos")
                                        .profileTextStyle()
                                }
                                
                                Spacer()
                                NavigationLink(destination: FriendsView().navigationTitle("Courtships").navigationBarTitleDisplayMode(.inline)) {
                                    
                                    
                                    VStack {
                                        Text("\(nc.userData.courtships.count)")
                                            .profileInfoStyle()
                                        Text("Courtships")
                                            .profileTextStyle()
                                    }
                                }
                            }
                            .padding(.horizontal)
                            
                        }
                        
                        
                        Text((yourself ? nc.userData.shared.display_name : user?.display_name) ?? "Unknown")
                            .profileInfoStyle()
                        
                        Text("The users will be able to write a description of themselves here, like on Instagram.")
                            .profileTextStyle()
                        
                        
                        Spacer()
                        
                        Text("\(nc.userData.shared.id) | User ID: \(yourself ? nc.userData.shared.id : user?.id ?? -1)")
                            .font(.footnote)
                            .foregroundColor(Color.green)
                        
                        
                    }.padding(.horizontal)
                    
                    
                }.navigationTitle((yourself ? nc.userData.shared.username : user?.username) ?? "Unknown")
                    .navigationBarItems(leading: Button(action: {
                        if (yourself) {
                            GIDSignIn.sharedInstance.signOut()
                            print("logged out")
                            nc.userData.loggedIn = false
                            //typeSelection = -1
                        } else {
                            self.presentationMode.wrappedValue.dismiss()
                        }
                    }, label: {
                        Text(yourself ? "Log Out" : "< Back")
                            .foregroundColor(yourself ? Color.red : .accentColor)
                            .fontWeight(.bold)
                    }),
                                        trailing:
                                            Button(action: {
                        presentingSettingsSheet = true
                    }, label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(Color.green)
                    })
                                            .opacity(yourself ? 1 : 0)
                                            .disabled(!yourself)
                    )
                
            }
        }
        .onAppear(perform: {initialize()})
        .sheet(isPresented: $presentingSettingsSheet, onDismiss: {initialize()}) {
            SettingsView()
        }
    }
}

//struct ProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//        ProfileView()
//    }
//}

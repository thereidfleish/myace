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
    var user: SharedData
    @State private var didAppear = false
    
//    func initialize() async {
//        do {
//            awaiting = true
////            try await nc.getCourtships(user_id: "me", type: nil)
////
////            if(!yourself) {
////                try await nc.getBuckets(userID: String(user.id))
////                try await nc.getOtherUserUploads(userID: user.id, bucketID: nil)
////
////            }
////            else {
////                try await nc.getBuckets(userID: String(nc.userData.shared.id))
////                try await nc.getMyUploads(shared_with_ID: nil, bucketID: nil)
////            }
//            awaiting = false
//        } catch {
//            print("Showing error: \(error)")
//            errorMessage = error.localizedDescription
//            showingError = true
//            awaiting = false
//        }
//    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading) {
                    
                    HStack {
                        AsyncImage(url: nc.userData.profilePic) { image in
                            yourself ? image.resizable() : Image(systemName: "person.crop.circle").resizable()
                        } placeholder: {
                            ZStack {
                                Circle()
                                    .foregroundColor(Color.green)
                                Text(user.display_name.prefix(1))
                                    .font(.largeTitle)
                                    .foregroundColor(Color.white)
                            }
                        }
                        .frame(width: 128, height: 128)
                        .clipShape(Circle())
                        
                        Spacer()
                        
                        HStack {
                            VStack {
                                Text(yourself ? String(nc.userData.uploads.count) : String(user.n_uploads))
                                    .videoInfoStyle()
                                    .foregroundColor(Color.green)
                                Text("Videos")
                                    .profileTextStyle()
                            }
                            
                            Spacer()
                            
                            NavigationLink(destination: FriendsView().navigationTitle("Courtships").navigationBarTitleDisplayMode(.inline)) {
                                
                                VStack {
                                    Text(String((user.n_courtships.coaches) + (user.n_courtships.students) + (user.n_courtships.friends)))
                                        .profileInfoStyle()
                                    Text("Courtships")
                                        .profileTextStyle()
                                }
                            }
                            .disabled(!yourself)
                        }
                        .padding(.horizontal)
                        
                    }
                    
                    
                    Text(user.display_name)
                        .profileInfoStyle()
                    
                    Text(user.biography)
                        .padding(.bottom)
                        .profileTextStyle()
                    

                    
    //                Text("User ID: \(user.id)")
    //                    .font(.footnote)
    //                    .foregroundColor(Color.green)
    //
                    StrokesView(otherUser: user, currentUserAs: .friend)
                    //StrokesView(otherUser: yourself ? nc.userData.shared : user!, filteredBucketsAndUploads: nc.userData.uploads)
                    //.onAppear(perform: {initialize()})
                    
                }.padding(.horizontal)
                
                
            }.navigationBarTitle(user.username, displayMode: .inline)
                .navigationBarItems(leading: Button(action: {
                    if (yourself) {
                        //GIDSignIn.sharedInstance.signOut()
                        nc.logOut()    
                    }
                }, label: {
                    if (yourself) {
                        Text("Log Out")
                            .foregroundColor(yourself ? Color.red : .accentColor)
                            .fontWeight(.bold)
                    }
                    
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
            
            
            
                .sheet(isPresented: $presentingSettingsSheet
    //                   ,onDismiss: {
    //                Task {
    //                    await initialize()
    //                }
    //            }
                ) {
                    SettingsView()
                }
    //            .task {
    //                await initialize()
    //            }
            if showingError {
                Message(title: "Error", message: errorMessage, style: .error, isPresented: $showingError, view: nil)
            }
        }
    }
}

//struct ProfileView_Previews: PreviewProvider {
//    static var previews: some View {
//        ProfileView()
//    }
//}

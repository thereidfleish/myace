//
//  ContentView.swift
//  Shared
//
//  Created by Reid Fleishman on 12/22/21.
//

import SwiftUI

struct ContentView: View {
    @State private var selection = 0
    @State private var showsUploadAlert = false
    @StateObject var studentInfo = StudentInfo()
    @StateObject var coachInfo = CoachInfo()
    @EnvironmentObject private var networkController: NetworkController
    var body: some View {
        TabView(selection: $selection) {
            if (networkController.userData.shared.type == 0) {
                StudentUploadView()
                    .environmentObject(studentInfo)
                    .environmentObject(coachInfo)
                    .tabItem {
                        VStack {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .foregroundColor(.green)
                            Text("Student View")
                                .foregroundColor(.green)
                        }
                    }
                    .tag(0)
            }
            else {
                CoachMainView()
                    .environmentObject(coachInfo)
                    .environmentObject(studentInfo)
                    .tabItem {
                        VStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.green)
                            Text("Coach View")
                                .foregroundColor(.green)
                        }
                    }
                    .tag(0)
            }
            
            SearchView()
                .tabItem {
                    VStack {
                        Image(systemName: "magnifyingglass.circle.fill")
                            .foregroundColor(.green)
                        Text("Search")
                            .foregroundColor(.green)
                    }
                }
                .tag(1)
            
            CameraView()
                .tabItem {
                    VStack {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.green)
                        Text("Camera")
                            .foregroundColor(.green)
                    }
                }
                .tag(2)
            /*
                .sheet(isPresented: $showsUploadAlert) {
                    NavigationView {
                        VStack {
                            TextField("My Video", text: $uploadName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            //.padding([.top, .leading, .trailing])
                            Text("Choose a bucket")
                                .bucketTextInternalStyle()
                            Picker("None Selected", selection: $uploadBucketName) {
                                ForEach(nc.userData.buckets, id: \.id) {
                                    Text($0.name)
                                }
                            }
                            //.pickerStyle(.)
                            
                            Spacer()
                            if url.count > 0 {
                                VideoPlayer(player: AVPlayer(url: url[0]))
                                    .frame(height: 300)
                            }
                            Spacer()
                            
                            Button(action: {
                                showsUploadAlert = false
                                uploadInit(fileURL: url[0], uploadName: uploadName)
                                
                            }, label: {
                                Text("Upload")
                                    .buttonStyle()
                                //.padding([.top, .leading, .trailing])
                            })
                            
                        }.padding()
                            .navigationTitle("Set Video Title")
                            .navigationBarItems(leading: Button(action: {
                                showsUploadAlert = false
                            }, label: {
                                Text("Cancel")
                                    .foregroundColor(Color.green)
                                    .fontWeight(.bold)
                            }))
                        
                    }
                    
                }
             */
            ProfileView(yourself: true, user: Friend(id: -1, username: "", display_name: "", type: -1))
                .tabItem {
                    VStack {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundColor(.green)
                        Text("My Profile")
                            .foregroundColor(.green)
                    }
                }
                .tag(3)
            
            
        }.accentColor(Color.green)
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

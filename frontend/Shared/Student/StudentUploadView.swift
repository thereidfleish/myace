//
//  StudentUploadView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/22/21.
//

import SwiftUI

struct StudentUploadView: View {
    @EnvironmentObject private var nc: NetworkController
    @EnvironmentObject var studentInfo: StudentInfo
    @State private var showingNewBucketView = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var bucketContents: [BucketContents] = []
    @State private var awaiting = false
    
    func initialize() {
        Task {
            do {
                awaiting = true
                
                //try await nc.authenticate(token: "test", type: nc.userData.shared.type)
                try await nc.getBuckets(uid: "\(nc.userData.shared.id)")
                print("DONE!")
            } catch {
                print(error)
                errorMessage = error.localizedDescription
                showingError = true
            }
            awaiting = false
            print(nc.userData.buckets)
        }
    }
    
    var body: some View {
        
        NavigationView {
            ScrollView {
                if (awaiting) {
                    ProgressView()
                } else if (showingError) {
                    Text("Error: \(errorMessage).  \(errorMessage.contains("0") ? "JSON Encode Error" : "JSON Decode Error").  Please check your internet connection, or try again later.").padding()
                } else {
                
                    //                Button(action: {
                    //
                    //                }, label: {
                    //                    Text("Create New Stroke")
                    //                        .padding(.vertical, 15)
                    //                        .frame(maxWidth: .infinity)
                    //                        .background(Color.green)
                    //                        .cornerRadius(10)
                    //                        .foregroundColor(.white)
                    //                })
                    //                    .padding([.horizontal, .top, .bottom])
                    
                    VStack(alignment: .leading) {
                        Text("\(UserData.computeWelcome()) \(nc.userData.shared.display_name)")
                            .font(.title2)
                            .fontWeight(.heavy)
                            .foregroundColor(Color.green)
                            .padding(.horizontal)
                        
                        ForEach(nc.userData.buckets, id: \.id) { bucket in
                            NavigationLink(destination: StudentUploadDetailView(name: bucket.name, student: true, uid: "\(nc.userData.shared.id)", bucketID: "\(bucket.id)").navigationTitle(bucket.name).navigationBarTitleDisplayMode(.inline))
                            {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(bucket.name)
                                            .font(.title2)
                                            .fontWeight(.heavy)
                                            .foregroundColor(Color.white)
                                        
                                        HStack {
                                            Image(systemName: "person.fill")
                                                .foregroundColor(Color.white)
                                                .frame(width: 15)
                                            Text("Trainer names will go here")
                                                .font(.subheadline)
                                                .foregroundColor(Color.white)
                                        }
                                        
                                        HStack {
                                            Image(systemName: "text.bubble.fill")
                                                .foregroundColor(.white)
                                                .frame(width: 15)
                                            if (/*studentInfo.numFeedback[i]*/ 0 == 0) {
                                                Text(/*"\(studentInfo.numFeedback[i])*/ "New Feedback")
                                                    .font(.subheadline)
                                                    .foregroundColor(Color.white)
                                            }
                                            else {
                                                Text(/*"*\(studentInfo.numFeedback[i])*/ "New Feedback")
                                                    .font(.subheadline)
                                                    .bold()
                                                    .foregroundColor(Color.white)
                                            }
                                            
                                        }
                                        
                                        HStack {
                                            Image(systemName: "clock.fill")
                                                .foregroundColor(.white)
                                                .frame(width: 15)

                                            Text(bucket.last_modified ?? "No uploads yet")
                                                .font(.subheadline)
                                                .foregroundColor(Color.white)
//                                            Text("\(nc.userData.buckets[i].id)")
//                                                .font(.subheadline)
//                                                .foregroundColor(Color.white)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right.square.fill")
                                        .resizable()
                                        .scaledToFill()
                                        .foregroundColor(Color.white)
                                        .frame(width: 20, height: 20)
                                }
                                .padding()
                                .background(Color.green)
                                .cornerRadius(10)
                                .padding(.horizontal)
                                .shadow(radius: 5)
                            }
                        }.sheet(isPresented: $showingNewBucketView) {
                            NewBucketView()
                            
                        }
                        
                    }
                }
                
            }.onAppear(perform: {initialize()})
            .navigationTitle("Uploads"/*, displayMode: .inline*/)
                .navigationBarItems(leading: Button(action: {
                    initialize()
                }, label: {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .foregroundColor(Color.green)
                }),trailing: Button(action: {
                    showingNewBucketView.toggle()
                }, label: {
                    Text("Add Stroke")
                        .foregroundColor(Color.green)
                        .fontWeight(.bold)
                }))
        }
    }
}


//struct StudentUploadView_Previews: PreviewProvider {
//    static var previews: some View {
//        StudentUploadView()
//    }
//}

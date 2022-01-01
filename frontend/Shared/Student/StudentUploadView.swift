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
                try await nc.getBuckets(uid: "2")
                
//                for bucket in nc.userData.buckets {
//                    try await bucketContents.append(nc.getBucketContents(uid: "2", bucketID: "\(bucket.id)"))
//                }
//
//
//
//                // THE below may execute syncronously, which may be an issue
//                for i in bucketContents.indices {
//                    bucketContents[i].uploads.sort(by: {$0.created > $1.created})
//                }
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
                        
                        ForEach(nc.userData.buckets.indices, id: \.self) { i in
                            NavigationLink(destination: StudentUploadDetailView(name: nc.userData.buckets[i].name, student: true, uid: "2", bucketID: "\(nc.userData.buckets[i].id)").navigationTitle(nc.userData.buckets[i].name).navigationBarTitleDisplayMode(.inline))
                            {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(nc.userData.buckets[i].name)
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
//                                            Text(nc.userData.buckets.count == bucketContents.count ? bucketContents[i].uploads.count > 0 ? bucketContents[i].uploads[0].created : "No uploads yet")
//                                                .font(.subheadline)
//                                                .foregroundColor(Color.white)
//                                            Text(data.bucketContents[i].uploads.count > 0 ? data.bucketContents[i].uploads[0].created : "No uploads yet")
//                                                .font(.subheadline)
//                                                .foregroundColor(Color.white)
//                                            Text(try nc.getBucketContents(uid: "2", bucketID: "\(data.bucketContents[i].id)").uploads.sorted(by: {$0.created > $1.created})[0].created)
//                                                .font(.subheadline)
//                                                .foregroundColor(Color.white)
                                            Text("created date will go here")
                                                .font(.subheadline)
                                                .foregroundColor(Color.white)
                                            Text("\(nc.userData.buckets[i].id)")
                                                .font(.subheadline)
                                                .foregroundColor(Color.white)
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

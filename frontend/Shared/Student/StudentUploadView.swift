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
    @State var didAppear = false
    
    func initialize() {
        if (!didAppear) {
            didAppear = true
            Task {
                do {
                    
                    awaiting = true
                    
                    //try await nc.authenticate(token: "test", type: nc.userData.shared.type)
                    try await nc.getBuckets()
                    awaiting = false
                    print("DONE!")
                } catch {
                    print(error)
                    errorMessage = error.localizedDescription
                    showingError = true
                    awaiting = false
                }
                
                print(nc.userData.buckets)
            }
        }
        
    }
    
    var body: some View {
        
        NavigationView {
            ScrollView {
                if (awaiting) {
                    ProgressView()
                } else if (showingError) {
                    Text(UserData.computeErrorMessage(errorMessage: errorMessage)).padding()
                } else {
                    
                    VStack(alignment: .leading) {
                        Text("\(UserData.computeWelcome()) \(UserData.firstName(name: nc.userData.shared.display_name))!")
                            .bucketNameStyle()
                            .foregroundColor(Color.green)
                        
                        ForEach(nc.userData.buckets) { bucket in
                            NavigationLink(destination: StudentUploadDetailView(student: true, bucketID: "\(bucket.id)").navigationTitle(bucket.name).navigationBarTitleDisplayMode(.inline))
                            {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(bucket.name)
                                            .bucketNameStyle()
                                            .foregroundColor(Color.white)
                                        
                                        HStack {
                                            Image(systemName: "person.fill")
                                                .foregroundColor(Color.white)
                                                .frame(width: 15)
                                            Text("Trainer names will go here")
                                                .bucketTextExternalStyle()
                                        }
                                        
                                        HStack {
                                            Image(systemName: "text.bubble.fill")
                                                .foregroundColor(.white)
                                                .frame(width: 15)
                                            if (/*studentInfo.numFeedback[i]*/ 0 == 0) {
                                                Text(/*"\(studentInfo.numFeedback[i])*/ "New Feedback")
                                                    .bucketTextExternalStyle()
                                            }
                                            else {
                                                Text(/*"*\(studentInfo.numFeedback[i])*/ "New Feedback")
                                                    .unreadBucketTextExternalStyle()
                                            }
                                            
                                        }
                                        
                                        HStack {
                                            Image(systemName: "clock.fill")
                                                .foregroundColor(.white)
                                                .frame(width: 15)
                                            
                                            Text(bucket.last_modified?.formatted() ?? "No uploads yet")
                                                .bucketTextExternalStyle()
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
                                .navigationLinkStyle()
                            }
                        }
                        
                    }.sheet(isPresented: $showingNewBucketView) {
                        NewBucketView()
                        
                    }
                }
                
            }.padding(.horizontal)
            .onAppear(perform: {initialize()})
                .navigationTitle("Uploads"/*, displayMode: .inline*/)
                .navigationBarItems(leading: Button(action: {
                    didAppear = false
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

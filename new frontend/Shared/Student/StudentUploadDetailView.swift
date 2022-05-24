//
//  StudentUploadDetailView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/22/21.
//

import SwiftUI

import Alamofire
//import AVKit



struct StudentUploadDetailView: View {
    @EnvironmentObject private var nc: NetworkController
    @State private var showingFeedback = false
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    
    @State private var showOnlyVideo = false
    
    @State private var isShowingMediaPicker = false
    @State private var isShowingCamera = false
    @State var url: [URL] = []
    @State private var originalName = ""
    var otherUser: SharedData
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var awaiting = false
    @State private var uploading = false
    @State private var uploadingStatus = ""
    @State private var progressPercent = ""
    @State private var showsUploadAlert = false
    @State private var uploadName = ""
    @State private var showingEditingName = false
    @State private var showingEditingNameUploadID: String = ""
    @State private var showingDelete = false
    @State private var showingDeleteUploadID: String = ""
    @State private var currentBucketID: Int = -1
    
    func initialize() async {
        do {
            awaiting = true
            print("getting buckets1")
            try await nc.getBuckets(userID: String(otherUser.id))
            print("getting uploads1")
            try await nc.getUploads(userID: otherUser.id, bucketID: nil)
            //try await nc.getUploads(getSpecificID: true, bucketID: bucketID)
            print("Finsihed init")
            awaiting = false
        } catch {
            print(error)
            errorMessage = error.localizedDescription
            showingError = true
            awaiting = false
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(otherUser.display_name)
                    .padding(.top)
                    .bucketTextInternalStyle()
                
                Text("Strokes")
                    .padding(.top)
                    .bucketTextInternalStyle()
                
                if (nc.userData.buckets.count == 0) {
                    Text("Welcome to your space with your coach, \(otherUser.display_name).  To start, create a stroke that ")
                        .multilineTextAlignment(.center)
                        .bucketTextInternalStyle()
                }
                
//                StrokesView(otherUser: otherUser, filteredBucketsAndUploads: nc.userData.uploads.filter { ($0.visibility.default != .private && $0.visibility.default != .friends_only) || ($0.visibility.also_shared_with.filter { $0.id == otherUser.id }.isEmpty == false) })
                //StrokesView(otherUser: otherUser, filteredBucketsAndUploads: nc.userData.uploads)
                StrokesView(otherUser: otherUser)
                
//                HStack {
//                    Button(action: {
//                        isShowingMediaPicker.toggle()
//                    }, label: {
//                        Text("Upload Video")
//                            .padding(.vertical, 15)
//                            .frame(maxWidth: .infinity)
//                            .overlay(
//                                RoundedRectangle(cornerRadius: 10)
//                                    .stroke(Color.green, lineWidth: 3)
//                            )
//                            .foregroundColor(.green)
//                    }).disabled(uploading)
//                        
//                    Button(action: {
//                        isShowingCamera.toggle()
//                    }, label: {
//                        Text("Capture a Video")
//                            .buttonStyle()
//                    })
//                    
//                    
//                }
//                .padding(.bottom)
                

                
            }.padding(.horizontal)
                .navigationBarItems(trailing: Refresher().refreshable {
                    await initialize()
                })
            
            
            
        }
        .task {
            await initialize()
        }
        
        
        
        
    }
}

//struct StudentUploadDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        StudentUploadDetailView()
//    }
//}

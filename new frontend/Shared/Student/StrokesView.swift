//
//  StrokesView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 5/23/22.
//

import SwiftUI
import MediaPicker

struct StrokesView: View {
    @EnvironmentObject private var nc: NetworkController
//    @State private var showingFeedback = false
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    var otherUser: SharedData
    var currentUserAs: CurrentUserAs
    @State private var isShowingNewStrokeView = false
    @State private var isShowingCamera = false
//    @State private var showingEditingName = false
//    @State private var showingEditingNameUploadID: String = ""
//    @State private var uploadName = ""
//    @State private var originalName = ""
//    @State private var showingDeleteUploadID: String = ""
//    @State private var showingDelete = false
    @State private var isShowingMediaPicker = false
    @State private var currentBucketID: Int = -1
    @State private var showsUploadAlert = false
    @State var url: [URL] = []
    
    //@State var filteredBucketsAndUploads: [Upload]
    @State private var visOptions: [VisibilityOptions: String] = [.`private`: "Private",
                                                                  .coaches_only: "Coaches Only",
                                                                  .friends_only: "Friends Only",
                                                                  .friends_and_coaches: "Friends and Coaches Only",
                                                                  .`public`: "Public"]
    @State private var showingError = false
    @State private var awaiting = true
    
    func initialize() async {
        do {
            awaiting = true
            print("getting buckets")
            try await nc.getBuckets(userID: currentUserAs == .coach || currentUserAs == .observer ? String(otherUser.id) : "me")
            print("getting uploads")
            if(currentUserAs == .coach || currentUserAs == .observer) {
                try await nc.getOtherUserUploads(userID: otherUser.id, bucketID: nil)
            }
            else if(currentUserAs == .student) {
                try await nc.getMyUploads(shared_with_ID: otherUser.id, bucketID: nil)
            }
//            else if (currentUserAs == .neitherStudentNorCoach) {
//                try await nc.getMyUploads(shared_with_ID: nil, bucketID: nil)
//            }
            awaiting = false
//            //try await nc.getMyUploads(userID: coach ? otherUser.id : nil, bucketID: nil)
            print("Finsihed init")
            
            
        } catch {
            showingError = true
            awaiting = false
            print(error)
        }
    }
    
    //    func editUpload(jj: String)  {
    //        Task {
    //            do {
    //                awaiting = true
    //                try await nc.editUpload(uploadID: jj, displayTitle: uploadName)
    //                awaiting = false
    //                initialize()
    //            } catch {
    //                print(error)
    //                errorMessage = error.localizedDescription
    //                showingError = true
    //                awaiting = false
    //            }
    //        }
    //    }
    
    var body: some View {
        VStack(alignment: .leading) {
            if(awaiting) {
                ProgressView()
            }
            else if(showingError) {
                Text(nc.errorMessage).padding()
            }
            else {
                HStack {
                    Text("Strokes")
                        .bucketTextInternalStyle()
                    if (currentUserAs == .student || otherUser.id == nc.userData.shared.id) {
                        Button(action: {
                            isShowingNewStrokeView.toggle()
                        }, label: {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .circularButtonStyle()
                        })
                    }
                }
                
                if (nc.userData.buckets.count == 0) {
                    Text("\(currentUserAs == .student ? "To start, create a stroke." : "It appears that \(otherUser.display_name) has not yet uploaded any videos that you can view.")")
                        .multilineTextAlignment(.center)
                        .bucketTextInternalStyle()
                }
                
                ForEach(nc.userData.buckets) { bucket in
                    HStack {
                        Text(bucket.name)
                        Spacer()
                        Button(action: {
                            currentBucketID = bucket.id
                            isShowingMediaPicker.toggle()
                        }, label: {
                            Image(systemName: "square.and.arrow.up.circle.fill")
                                .resizable()
                                .circularButtonStyle()
                        })
                        
                        if (currentUserAs == .student || otherUser.id == nc.userData.shared.id) {
                            Menu {
                                Button {
                                    
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    Task {
                                        try await nc.deleteBucket(bucketID: String(bucket.id))
                                        await initialize()
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                
                            } label: {
                                Image(systemName: "ellipsis.circle.fill")
                                    .resizable()
                                    .circularButtonStyle()
                            }
                        }
                        
                    }
                    
                    
                    //ForEach(filteredBucketsAndUploads.filter { $0.bucket.id == bucket.id }) { upload in
                    ExternalUploadView(bucket: bucket, otherUser: otherUser, currentUserAs: currentUserAs)
                }
            }
            
        }
        .mediaImporter(isPresented: $isShowingMediaPicker,
                       allowedMediaTypes: .all,
                       allowsMultipleSelection: false) { result in
            switch result {
            case .success(let url):
                self.url = url
                print(url)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showsUploadAlert = true
                }
            case .failure(let error):
                print(error)
                self.url = []
            }
        }.sheet(isPresented: $showsUploadAlert, onDismiss: {
            Task {
                await initialize()
            }
            
        }) {
            UploadView(url: url, bucketID: String(currentBucketID), otherUser: otherUser) // place this in each bucket so that
        }
//        .sheet(isPresented: $isShowingCamera) {
//            CameraView(otherUser: otherUser)
//        }
        .sheet(isPresented: $isShowingNewStrokeView, onDismiss: {
            Task {
                await initialize()
            }
        }) {
            NewBucketView()
        }
        .task {
            await initialize()
        }
    }
}

//struct StrokesView_Previews: PreviewProvider {
//    static var previews: some View {
//        StrokesView()
//    }
//}

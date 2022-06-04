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
    @State private var collapsed = false
    @State private var showingDelete = false
    @State private var showingDeleteUploadID: String = ""
    @State private var showingEditingUpload = false
    
    
    //@State var filteredBucketsAndUploads: [Upload]
    
    @State private var showingError = false
    @State private var awaiting = true
    let visOptions: [VisibilityOptions: String] = [.`private`: "Private",
                                                   .coaches_only: "Coaches Only",
                                                   .friends_only: "Friends Only",
                                                   .friends_and_coaches: "Friends and Coaches Only",
                                                   .`public`: "Public"]
    
    func initialize(showProgressView: Bool) async {
        do {
            if (showProgressView) {
                awaiting = true
            }
            
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
    
    var body: some View {
        LazyVStack(alignment: .leading, pinnedViews: [.sectionHeaders]) {
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
                .padding(.bottom)
                
                if (nc.userData.buckets.count == 0) {
                    Text("\(currentUserAs == .student ? "To start, create a stroke." : "It appears that \(otherUser.display_name) has not yet uploaded any videos that you can view.")")
                        .multilineTextAlignment(.center)
                        .bucketTextInternalStyle()
                }
                
                ForEach(nc.userData.buckets) { bucket in
                    Section(header: HStack {
                        //                        Button(action: {
                        //                            withAnimation {
                        //                                collapsed.toggle()
                        //                            }
                        //
                        //                        }, label: {
                        //                            Image(systemName: "chevron.right")
                        //                                .resizable()
                        //                                .circularButtonStyle()
                        //                        })
                        
                        Text(bucket.name)
                            .bucketTextInternalStyle()
                        
                        Spacer()
                        
                        if (currentUserAs == .student || otherUser.id == nc.userData.shared.id) {
                            Button(action: {
                                currentBucketID = bucket.id
                                isShowingMediaPicker.toggle()
                            }, label: {
                                Image(systemName: "video.circle.fill")
                                    .resizable()
                                    .circularButtonStyle()
                            })
                            
                            Menu {
                                Button {
                                    
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    Task {
                                        awaiting = true
                                        try await nc.deleteBucket(bucketID: String(bucket.id))
                                        await initialize(showProgressView: true)
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
                        
                    }.id("\(bucket.id)-1")
                        .background(Color.white)
                            , content: {
                        ForEach(nc.userData.uploads.filter{ $0.bucket.id == bucket.id } ) { upload in
                            HStack {
                                if (showingDelete && String(upload.id) == showingDeleteUploadID) {
                                    Text("Are you sure you want to delete this video?  This cannot be undone!")
                                        .foregroundColor(.red)
                                    Button(action: {
                                        Task {
                                            awaiting = true
                                            try await nc.deleteUpload(uploadID: String(upload.id))
                                            await initialize(showProgressView: true)
                                        }
                                        
                                    }, label: {
                                        Text("Delete")
                                            .foregroundColor(.red)
                                            .fontWeight(.bold)
                                    })
                                }
                                
                            }
                            
                            Spacer()
                            
                            
                            HStack {
                                VideoThumbnailView(upload: upload)
                                
                                VStack(alignment: .leading) {
                                    Text(upload.display_title == "" ? "Untitled" : upload.display_title)
                                        .smallestSubsectionStyle()
                                    
                                    Text(upload.created.formatted())
                                        .font(.subheadline)
                                        .foregroundColor(Color.green)
                                    
                                    Text(visOptions[upload.visibility.default]!)
                                        .font(.subheadline)
                                        .foregroundColor(Color.green)
                                    
                                    
                                    //Text("\(upload.id)")
                                    
                                    if (!upload.stream_ready) {
                                        Text("Processing video, please wait...")
                                            .font(.footnote)
                                            .foregroundColor(Color.green)
                                    }
                                    else if (currentUserAs == .student || otherUser.id == nc.userData.shared.id) {
                                        // If you're a student or viewing your own profile you can edit the uploads.
                                        Menu {
                                            Button {
                                                nc.editUploadID = String(upload.id)
                                                showingEditingUpload = true
                                            } label: {
                                                Label("Edit Upload", systemImage: "pencil")
                                            }
                                            
                                            Button(role: .destructive) {
                                                withAnimation {
                                                    if (showingDeleteUploadID == String(upload.id)) {
                                                        showingDelete.toggle()
                                                    } else {
                                                        showingDelete = true
                                                    }
                                                    showingDeleteUploadID = String(upload.id)
                                                }
                                                
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                            
                                        } label: {
                                            Image(systemName: "ellipsis.circle.fill")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 25, height: 25)
                                        }
                                    }
                                    
                                    
                                    Spacer()
                                }
                            }.id("\(upload.id)-2")
                        }
                    })
                }
                //                .overlay(
                //                    RoundedRectangle(cornerRadius: 10)
                //                        .stroke(Color.green, lineWidth: 3)
                //                )
            }
            
        }
        .mediaImporter(isPresented: $isShowingMediaPicker,
                       allowedMediaTypes: .videos,
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
                await initialize(showProgressView: true)
            }
            var timer = Timer()
            DispatchQueue.main.async {
                timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { _ in
                    Task {
                        await initialize(showProgressView: false)
                        if (!nc.userData.uploads.contains(where: { $0.stream_ready == false })) {
                            timer.invalidate()
                        }
                    }
                })
            }
            
        }) {
            UploadView(url: url, bucketID: String(currentBucketID), otherUser: otherUser) // place this in each bucket so that
        }
        //        .sheet(isPresented: $isShowingCamera) {
        //            CameraView(otherUser: otherUser)
        //        }
        .sheet(isPresented: $isShowingNewStrokeView, onDismiss: {
            Task {
                await initialize(showProgressView: true)
            }
        }) {
            NewBucketView()
        }
        .sheet(isPresented: $showingEditingUpload, onDismiss: {
            Task {
                await initialize(showProgressView: true)
            }
        }) {
            UploadView(url: [], bucketID: "", otherUser: otherUser, editMode: true)
        }
        .navigationBarItems(trailing: Refresher().refreshable {
            await initialize(showProgressView: true)
        })
        .task {
            await initialize(showProgressView: true)
        }
    }
}

//struct StrokesView_Previews: PreviewProvider {
//    static var previews: some View {
//        StrokesView()
//    }
//}

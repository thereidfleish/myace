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
    @Environment(\.colorScheme) var colorScheme
    var otherUser: SharedData
    var currentUserAs: CurrentUserAs
    @State private var isShowingNewStrokeView = false
    @State private var isShowingCamera = false
    @State private var showingEditingBucketName = false
    @State private var editingName: String = ""
    @State private var editingBucketNameBucketID: String = ""
    @State private var showingDeleteBucket = false
    @State private var deletingBucketID: String = ""
    @State private var isShowingMediaPicker = false
    @State private var currentBucketID: Int = -1
    @State private var showsUploadAlert = false
    @State var url: [URL] = []
    @State private var collapsed = false
    @State private var showingDeleteUpload = false
    @State private var showingDeleteUploadID: String = ""
    @State private var showingEditingUpload = false
    
    @State private var errorMessage = ""
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
            awaiting = false
            print("Finsihed init")
            
            
        } catch {
            print("Showing error: \(error)")
            nc.showingMessage = true
            nc.messageView = AnyView(
                Message(title: "Error", message: error.localizedDescription, style: .error, isPresented: $nc.showingMessage, view: nil)
            )
            awaiting = false
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
                        Text("Folders")
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
                        Text("\(currentUserAs == .student ? "Create a folder to store your videos." : "It appears that \(otherUser.display_name) has not yet uploaded any videos that you can view.")")
                            .multilineTextAlignment(.center)
                    }
                    
                    ForEach(nc.userData.buckets) { bucket in
                        Section(header:
                                    VStack {
                            HStack(alignment: .center) {
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
                                editingName = ""
                                nc.showingMessage = true
                                    nc.messageView = AnyView(
                                        Message(title: "Edit Folder Name", message: "Provide a new name for the folder, \"\(bucket.name)\"", style: .message, isPresented: $nc.showingMessage, view: AnyView(
                                            HStack {
                                                TextField("Edit name", text: $editingName)
                                                    .textFieldStyle()

                                                Button(action: {
                                                    Task {
                                                        nc.showingMessage = false
                                                        awaiting = true
                                                        do {
                                                            try await nc.editBucket(bucketID: String(bucket.id), newName: editingName)
                                                            await initialize(showProgressView: true)
                                                            awaiting = false
                                                        } catch {
                                                            errorMessage = error.localizedDescription
                                                            showingError = true
                                                            awaiting = false
                                                        }
                                                        showingEditingBucketName = false
                                                    }

                                                }, label: {
                                                    Text("Save")
                                                        .bold()
                                                        .foregroundColor(.green)
                                                })
                                            }
                                        ))
                                    )
                                
                                
                            } label: {
                                Label("Rename Folder", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                nc.showingMessage = true
                                nc.messageView = AnyView(
                                    Message(title: "Delete Folder", message: "Are you sure you want to delete this folder, \"\(bucket.name)\", and its videos?  This cannot be undone!", style: .delete, isPresented: $nc.showingMessage, view: AnyView(
                                            Button(action: {
                                                Task {
                                                    nc.showingMessage = false
                                                    awaiting = true
                                                    do {
                                                        try await nc.deleteBucket(bucketID: String(bucket.id))
                                                        await initialize(showProgressView: true)
                                                        awaiting = false
                                                    } catch {
                                                        errorMessage = error.localizedDescription
                                                        showingError = true
                                                        awaiting = false
                                                    }
                                                    showingDeleteBucket = false
                                                }

                                            }, label: {
                                                Text("Delete")
                                                    .messageButtonStyle()
                                            })
                                    ))
                                )
                            } label: {
                                Label("Delete Folder", systemImage: "trash")
                            }
                            
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .resizable()
                                .circularButtonStyle()
                        }
                    }
                    
                }.padding(.bottom, -5)
                                .padding(.top, 5)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.green)
                                .frame(height: 2)
                                
                        }
                                    
//                            .padding(5)
//                            .overlay(
//                                                    RoundedRectangle(cornerRadius: 10)
//                                                        .stroke(Color.green, lineWidth: 3)
//                                                )
                            .id("\(bucket.id)-1")
                            .background(colorScheme == .dark ? .black : .white)
                                
                                
                                , content: {
                            VStack {
                                let filteredUploads = nc.userData.uploads.filter{ $0.bucket.id == bucket.id }
                                if (filteredUploads.isEmpty) {
                                    Text("Tap the Camera icon to upload your first video into \"\(bucket.name)\"")
                                }
                                ForEach(filteredUploads) { upload in
                                    
                                    
                                    //Spacer() // For some reason, app does not compile without this spacer!
                                    
                                    HStack(alignment: .top) {
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
                                                        nc.showingMessage = true
                                                        nc.messageView = AnyView(
                                                            Message(title: "Delete Upload", message: "Are you sure you want to delete the video, \"\(upload.display_title)\", and its comments?  This cannot be undone!", style: .delete, isPresented: $nc.showingMessage, view: AnyView(
                                                                    Button(action: {
                                                                        Task {
                                                                            nc.showingMessage = false
                                                                            awaiting = true
                                                                            do {
                                                                                try await nc.deleteUpload(uploadID: String(upload.id))
                                                                                await initialize(showProgressView: true)
                                                                                awaiting = false
                                                                            } catch {
                                                                                errorMessage = error.localizedDescription
                                                                                showingError = true
                                                                                awaiting = false
                                                                            }

                                                                            showingDeleteUpload = false
                                                                        }

                                                                    }, label: {
                                                                        Text("Delete")
                                                                            .messageButtonStyle()
                                                                    })
                                                            ))
                                                        )
                                                        
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
                                            
                                            
                                            //Spacer()
                                        }
                                    }.id("\(upload.id)-2")
                                        //.padding(.bottom)
                                }
                            }
                        })
                    }

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

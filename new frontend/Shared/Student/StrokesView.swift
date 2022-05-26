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
    @State private var showingFeedback = false
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    var otherUser: SharedData
    var coach: Bool
    @State private var isShowingNewStrokeView = false
    @State private var isShowingCamera = false
    @State private var showingEditingName = false
    @State private var showingEditingNameUploadID: String = ""
    @State private var uploadName = ""
    @State private var originalName = ""
    @State private var showingDeleteUploadID: String = ""
    @State private var showingDelete = false
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
    @State private var awaiting = false
    
    func initialize() async {
        do {
            awaiting = true
            print("getting buckets")
            try await nc.getBuckets(userID: coach ? String(otherUser.id) : nil)
            print("getting uploads")
            //try await nc.getUploads(userID: nc.userData.shared.id, bucketID: nil)
            try await nc.getUploads(userID: coach ? otherUser.id : nil, bucketID: nil)
            print("Finsihed init")
            awaiting = false
            
        } catch {
            print(error)
        }
    }
    
    func delete(uploadID: String)  {
        Task {
            do {
                try await nc.deleteUpload(uploadID: uploadID)
                await initialize()
            } catch {
                print(error)
            }
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
            } else {
                HStack {
                    Text("Strokes")
                        .bucketTextInternalStyle()
                    if (!coach) {
                        Button(action: {
                            isShowingNewStrokeView.toggle()
                        }, label: {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .circularButtonStyle()
                        })
                    }
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
                        Button(action: {
                            isShowingCamera.toggle()
                        }, label: {
                            Image(systemName: "camera.circle.fill")
                                .resizable()
                                .circularButtonStyle()
                        })
                        
                        if (!coach) {
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
                    ForEach(nc.userData.uploads.filter{ $0.bucket.id == bucket.id } ) { upload in
                        HStack {
                            if (showingEditingName && String(upload.id) == showingEditingNameUploadID) {
                                //HStack {
                                TextField("Edit Name", text: $uploadName)
                                    .textFieldStyle()
                                    .onAppear(perform: {
                                        uploadName = upload.display_title
                                        originalName = uploadName
                                    })
                                
                                Button(action: {
                                    //editUpload(jj: "\(upload.id)")
                                    showingEditingName = false
                                }, label: {
                                    Text("Save")
                                        .foregroundColor(uploadName == originalName ? Color.gray : Color.green)
                                        .fontWeight(.bold)
                                })
                                .disabled(uploadName == originalName)
                                //}.padding(.horizontal)
                            }
                            
                            if (showingDelete && String(upload.id) == showingDeleteUploadID) {
                                //HStack {
                                Text("Are you sure you want to delete this video?  This cannot be undone!")
                                    .foregroundColor(.red)
                                Button(action: {
                                    delete(uploadID: String(upload.id))
                                }, label: {
                                    Text("Delete")
                                        .foregroundColor(.red)
                                        .fontWeight(.bold)
                                })
                                //}.padding(.horizontal)
                            }
                            
                        }
                        
                        Spacer()
                        
                        
                        HStack {
                            VideoThumbnailView(upload: upload)
                            
                            VStack(alignment: .leading) {
                                Text(upload.display_title == "" ? "Untitled" : upload.display_title)
                                    .videoInfoStyle()
                                    .foregroundColor(Color.green)
                                
                                Text(upload.created.formatted())
                                    .font(.subheadline)
                                    .foregroundColor(Color.green)
                                
                                Text("\(upload.id)")
                                
                                HStack {
                                    Button(action: {
                                        showingFeedback.toggle()
                                    }, label: {
                                        
                                        if (!upload.stream_ready) {
                                            Text("Processing video, please wait...")
                                                .font(.footnote)
                                                .foregroundColor(Color.green)
                                        }
                                        
                                      
                                        
                                    })
                                    
                                    Menu {
                                        Button {
                                            withAnimation {
                                                if (showingDelete) {
                                                    showingDelete = false
                                                }
                                                if (showingEditingNameUploadID == String(upload.id)) {
                                                    showingEditingName.toggle()
                                                } else {
                                                    showingEditingName = true
                                                }
                                                showingEditingNameUploadID = String(upload.id)
                                            }
                                            
                                            
                                        } label: {
                                            Label("Rename", systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive) {
                                            withAnimation {
                                                if (showingEditingName) {
                                                    showingEditingName = false
                                                }
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
                                    .padding(.leading)
                                    
                                }
                                
                                Spacer()
                            }
                        }
                    }
                }
            }
            .task {
                await initialize()
            } // THIS IS THE CULPRIT
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
        }
        
    }
}

//struct StrokesView_Previews: PreviewProvider {
//    static var previews: some View {
//        StrokesView()
//    }
//}

//
//  ExternalUploadView.swift
//  AI Tennis Coach
//
//  Created by AndrewC on 5/26/22.
//

import SwiftUI

struct ExternalUploadView: View {
    @EnvironmentObject private var nc: NetworkController
    @State private var showingFeedback = false
    var bucket: Bucket
    var coach: Bool
    var otherUser: SharedData
    @State private var showingEditingName = false
    @State private var showingEditingNameUploadID: String = ""
    @State private var uploadName = ""
    @State private var originalName = ""
    @State private var showingDeleteUploadID: String = ""
    @State private var showingDelete = false
    @State private var awaiting = true
    
    func initialize() async {
        do {
            awaiting = true
            print("getting uploads")
            try await nc.getUploads(userID: coach ? otherUser.id : nil, bucketID: nil)
            awaiting = false
            print("Finished init")
            
            
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
    
    var body: some View {
        if(awaiting) {
            ProgressView()
                .task {
                    await initialize()
                }
        } else {
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
}

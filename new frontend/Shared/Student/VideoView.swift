//
//  VideoView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 7/2/22.
//

import SwiftUI

struct VideoView: View {
    @EnvironmentObject private var nc: NetworkController
    
    var upload: Upload
    var currentUserAs: CourtshipType
    var otherUser: SharedData
    var initialize: () -> Void
    
    @State private var showingEditingUpload = false
    @State private var showingDeleteUpload = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var awaiting = true
    
    
    var body: some View {
        ZStack {
            HStack(alignment: .top) {
                NavigationLink(destination: StudentFeedbackView(student: true, uploadID: "\(upload.id)").navigationTitle("Feedback").navigationBarTitleDisplayMode(.inline))
                {
                    if (!upload.stream_ready) {
                        ProgressView()
                    } else {
                        AsyncImage(url: URL(string: upload.thumbnail!)!) { image in
                            image.resizable()
                        } placeholder: {
                            ProgressView()
                        }
                        .scaledToFill()
                        .frame(width: 200, height: 125)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        
                    }
                    
                }.disabled(!upload.stream_ready)
                    .padding([.trailing], 5)
                
                VStack(alignment: .leading) {
                    Text(upload.display_title == "" ? "Untitled" : upload.display_title)
                        .smallestSubsectionStyle()
                    
                    Text(upload.created.formatted())
                        .font(.subheadline)
                        .foregroundColor(Color.green)
                    
                    Text(nc.visOptions[upload.visibility.default]!)
                        .font(.subheadline)
                        .foregroundColor(Color.green)
                    
                    
                    //Text("\(upload.id)")
                    
                    if (!upload.stream_ready) {
                        Text("Processing video, please wait...")
                            .font(.footnote)
                            .foregroundColor(Color.green)
                    }
                    if (currentUserAs == .student || otherUser.id == nc.userData.shared.id) {
                        // If you're a student or viewing your own profile you can edit the uploads.
                        Menu {
                            Button {
                                nc.editUploadID = String(upload.id)
                                showingEditingUpload = true
                            } label: {
                                Label("Edit Video", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive) {
                                nc.showingMessage = true
                                nc.messageView = AnyView(
                                    Message(title: "Delete Video", message: "Are you sure you want to delete the video, \"\(upload.display_title)\", and its comments?  This cannot be undone!", style: .delete, isPresented: $nc.showingMessage, view: AnyView(
                                        Button(action: {
                                            Task {
                                                nc.showingMessage = false
                                                awaiting = true
                                                do {
                                                    try await nc.deleteUpload(uploadID: String(upload.id))
                                                    initialize()
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
                }
            }
            .sheet(isPresented: $showingEditingUpload, onDismiss: {
                Task {
                    initialize()
                }
            }) {
                UploadView(url: [], bucketID: "", otherUser: otherUser, editMode: true)
        }
            if showingError {
                Message(title: "Error", message: errorMessage, style: .error, isPresented: $showingError, view: nil)
            }
        }
    }
}

//struct VideoView_Previews: PreviewProvider {
//    static var previews: some View {
//        VideoView()
//    }
//}

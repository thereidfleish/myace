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
    var showAsMe: Bool
    
    @State private var showingEditingUpload = false
    @State private var showingDeleteUpload = false
    @State private var errorMessage = ""
    @State private var showingError = false
    @State private var awaiting = true
    
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading) {
                HStack {
                    
                    if (!showAsMe) {
                        NavigationLink(destination: ProfileView(yourself: false, user: otherUser)) {
                            switch otherUser.courtship?.type {
                            case .friend:
                                Image(systemName: "face.smiling.fill").foregroundColor(.green)
                            case .coach:
                                Image(systemName: "rectangle.inset.filled.and.person.filled").foregroundColor(.green)
                            case .student:
                                Image(systemName: "graduationcap.fill").foregroundColor(.green)
                            default:
                                Image(systemName: "person.fill.questionmark").foregroundColor(.green)
                            }
                            
                            Text(otherUser.display_name)
                                .smallestSubsectionStyle()
                        }
                        
                    } else {
                        NavigationLink(destination: ProfileView(yourself: true, user: nc.userData.shared)) {
                            Image(systemName: "person.crop.circle.fill").foregroundColor(.green)
                            
                            Text("Me")
                                .smallestSubsectionStyle()
                        }
                        
                    }
                    
                    Spacer()
                    
                    Text(upload.display_title == "" ? "Untitled" : upload.display_title)
                        .smallestSubsectionStyle()
                    
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
                }.padding(.bottom, -5)
                    .padding(.top, 10)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.green)
                    .frame(height: 2)
                
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
                        Text(upload.created.formatted())
                            .font(.subheadline)
                        //.foregroundColor(Color.green)
                        
                        HStack {
                            Image(systemName: "eye.circle.fill")
                            
                            Text(nc.visOptions[upload.visibility.default]!)
                                .font(.subheadline)
                            //.foregroundColor(Color.green)
                        }.padding(.top, 1)
                        
                        HStack {
                            Image(systemName: "tag.circle.fill")
                            
                            Text(upload.bucket.name)
                                .font(.subheadline)
                            //.foregroundColor(Color.green)
                        }.padding(.top, 1)
                        
                        if (!upload.stream_ready) {
                            Text("Processing video, please wait...")
                                .font(.footnote)
                                .foregroundColor(Color.green)
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

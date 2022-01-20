//
//  StudentUploadDetailView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/22/21.
//

import SwiftUI
import MediaPicker
import Alamofire
import AVKit



struct StudentUploadDetailView: View {
    @EnvironmentObject private var nc: NetworkController
    @State private var showingFeedback = false
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    
    // Settings for the Feedback/Video view
    @State private var showOnlyVideo = false
    //@State private var uploadID = ""
    
    @State private var isShowingMediaPicker = false
    @State private var isShowingCamera = false
    @State var url: [URL] = []
    @State private var name = ""
    @State private var originalName = ""
    var student: Bool
    //@State private var bucketContents: BucketContents = BucketContents(id: -1, name: "", user_id: -1, uploads: [])
    var bucketID: String
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var awaiting = false
    @State private var uploading = false
    @State private var uploadingStatus = ""
    @State private var progressPercent = ""
    @State private var showsUploadAlert = false
    @State private var uploadName = ""
    @State private var uploadBucketName = ""
    
    func initialize() {
        Task {
            do {
                awaiting = true
                //try await bucketContents = nc.getBucketContents(uid: "2", bucketID: "\(bucketID)")
                try await nc.getBucketContents(uid: "\(student ? nc.userData.shared.id : 4)", bucketID: "\(student ? bucketID : "9")")
                name = nc.userData.bucketContents.name
                print("Finsihed init")
                awaiting = false
                //nc.userData.bucketContents.uploads.sort(by: {$0.created > $1.created})
            } catch {
                print(error)
                errorMessage = error.localizedDescription
                showingError = true
                awaiting = false
            }
        }
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading) {
                    if (awaiting) {
                        ProgressView()
                    } else if (showingError) {
                        Text(UserData.computeErrorMessage(errorMessage: errorMessage)).padding()
                    } else {
                        Text("Edit Name")
                            .bucketTextInternalStyle()
                            .padding([.top, .leading, .trailing])
                        
                        HStack {
                            TextField("Edit Name", text: $name)
                                .textFieldStyle()
                                .onAppear(perform: {
                                    self.originalName = name
                                })
                            
                            Button(action: {
                                print("save")
                                originalName = name
                            }, label: {
                                Text("Save")
                                    .foregroundColor(name == originalName ? Color.gray : Color.green)
                                    .fontWeight(.bold)
                            })
                                .disabled(name == originalName)
                        }.padding(.horizontal)
                        
                        Text("Videos")
                            .bucketTextInternalStyle()
                            .padding([.top, .leading, .trailing])
                        
                        if (student) {
                            HStack {
                                Button(action: {
                                    isShowingMediaPicker.toggle()
                                }, label: {
                                    Text("Upload Video")
                                        .padding(.vertical, 15)
                                        .frame(maxWidth: .infinity)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.green, lineWidth: 3)
                                        )
                                        .foregroundColor(.green)
                                }).disabled(uploading)
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
                                            uploadBucketName = name
                                            //uploadInit(fileURL: url[0])
                                        case .failure(let error):
                                            print(error)
                                            self.url = []
                                        }
                                    }
                                   .sheet(isPresented: $showsUploadAlert) {
                                       UploadView(url: url, uploadInCurrentBucket: true, bucketID: bucketID)
                                       
                                   }
                                Button(action: {
                                    isShowingCamera.toggle()
                                }, label: {
                                    Text("Capture a Video")
                                        .buttonStyle()
                                })
                                    .sheet(isPresented: $isShowingCamera) {
                                        CameraView()
                                        
                                    }
                                
                            }.padding([.horizontal, .bottom])
                        }
                        
                        ForEach(nc.userData.bucketContents.uploads) { upload in
                            HStack {
                                NavigationLink(destination: StudentFeedbackView(text: "SJ", student: true, showOnlyVideo: true, uploadID: "\(upload.id)").navigationTitle("Feedback").navigationBarTitleDisplayMode(.inline))
                                {
                                    if (!upload.stream_ready) {
                                        ProgressView()
                                    } else {
                                        Image("testimage")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(maxWidth: 200, maxHeight: 200)
                                            .cornerRadius(10)
                                            .shadow(radius: 5)
                                    }
                                    
                                }.disabled(!upload.stream_ready)
                                
                                //                                 Button(action: {
                                //                                     showingFeedback.toggle()
                                //                                 }, label: {
                                //                                     if (!upload.stream_ready) {
                                //                                         ProgressView()
                                //                                     } else {
                                //                                         Image("testimage")
                                //                                             .resizable()
                                //                                             .scaledToFill()
                                //                                             .frame(maxWidth: 200, maxHeight: 200)
                                //                                             .cornerRadius(10)
                                //                                             .shadow(radius: 5)
                                //                                     }
                                //
                                //                                 }).sheet(isPresented: $showingFeedback) {
                                //                                     StudentFeedbackView(text: "This is some sample feedback", student: student, showOnlyVideo: true, uploadID: "\(upload.id)")
                                //                                 }
                                
                                VStack(alignment: .leading) {
                                    Text(upload.display_title == "" ? "Untitled" : upload.display_title)
                                        .videoInfoStyle()
                                        .foregroundColor(Color.green)
                                    
                                    Text(upload.created.formatted())
                                        .font(.subheadline)
                                        .foregroundColor(Color.green)
                                    
                                    Text("\(upload.id)")
                                    
                                    Button(action: {
                                        showingFeedback.toggle()
                                    }, label: {
                                        
                                        if (!upload.stream_ready) {
                                            Text("Processing video, please wait...")
                                                .font(.footnote)
                                                .foregroundColor(Color.green)
                                        }
                                        
                                        else if (upload.comments.count == 0) {
                                            Image(systemName: student ? "person.crop.circle.badge.clock.fill" : "plus.bubble.fill")
                                                .resizable()
                                                .scaledToFill()
                                                .foregroundColor(student ? Color.gray: Color.green)
                                                .frame(width: 25, height: 25)
                                                .opacity(student ? 0.5 : 1)
                                        }
                                        //                                if (studentInfo.feedbacks[i] == .unread) {
                                        //                                    Image(systemName: "text.bubble.fill")
                                        //                                        .resizable()
                                        //                                        .scaledToFill()
                                        //                                        .foregroundColor(Color.green)
                                        //                                        .frame(width: 25, height: 25)
                                        //                                }
                                        //                                if (studentInfo.feedbacks[i] == .read) {
                                        //                                    Image(systemName: "text.bubble.fill")
                                        //                                        .resizable()
                                        //                                        .scaledToFill()
                                        //                                        .foregroundColor(Color.gray)
                                        //                                        .frame(width: 25, height: 25)
                                        //                                }
                                        
                                    })
                                        .disabled(upload.comments.count == 0 && student ? true : false)
                                    
                                    Spacer()
                                    
                                    //                                                                 Text("\(studentInfo.times[i]) | \(studentInfo.sizes[i])")
                                    //                                                                     .font(.footnote)
                                    //                                                                     .foregroundColor(Color.green)
                                    
                                    
                                    
                                }.padding(.leading, 1)
                            }
                            .padding(.horizontal)
                        }
                    }
                }.navigationBarItems(trailing: Button(action: {
                    initialize()
                }, label: {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .foregroundColor(Color.green)
                }))
                
                
                
            }.onAppear(perform: {initialize()})
        }

            
        
    }
}

//struct StudentUploadDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        StudentUploadDetailView()
//    }
//}

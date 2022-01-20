//
//  StudentFeedbackView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/22/21.
//

import SwiftUI
import AVKit

struct StudentFeedbackView: View {
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    @EnvironmentObject private var nc: NetworkController
    @State var text: String
    var student: Bool
    var showOnlyVideo: Bool
    var uploadID: String
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var awaiting = true
    @State private var upload: Upload = Upload(id: -1, created: Date(), display_title: "", stream_ready: false, bucket_id: -1, comments: [], url: "")
    @State var didAppear = false
    @State private var player = AVPlayer(url:  URL(string: "http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8")!)
    
    func initialize() {
        if (!didAppear) {
            didAppear = true
            Task {
                do {
                    awaiting = true
                    print(uploadID)
                    try await upload = nc.getUpload(uid: "\(nc.userData.shared.id)", uploadID: uploadID)
                    //try await nc.getUpload2(url: upload.url!)
                    player = AVPlayer(url:  URL(string: upload.url!)!)
                    print(upload.url!)
                    print("DONE!")
                    awaiting = false
                } catch {
                    print(error)
                    errorMessage = error.localizedDescription
                    showingError = true
                    awaiting = false
                }
            }
        }
    }
    
    func delete()  {
        
        Task {
            do {
                print(uploadID)
                try await nc.deleteUpload(uploadID: uploadID)
                self.mode.wrappedValue.dismiss()
            } catch {
                print(error)
                errorMessage = error.localizedDescription
                showingError = true
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
                        VideoPlayer(player: player)
                            .frame(height: 300)
                        
                        Button("tap me!") {
                            print(player.currentItem?.duration.seconds)
                            print(player.currentTime().seconds)
                        }
                        
                        
                        Button("no tap me instead!") {
                            delete()
                        }
                        
                        if (!showOnlyVideo) {
                            if (student) {
                                Text(text)
                                    .multilineTextAlignment(.leading)
                                
                                
                            }
                            else {
                                
                                Text("Unsaved changes")
                                    .font(.footnote)
                                    .foregroundColor(Color.red)
                                
                                TextEditor(text: $text)
                                    .padding(1)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 5)
                                            .stroke(Color.gray, lineWidth: 1)
                                    )
                                    .frame(minHeight: UIScreen.screenHeight - 200)
                                
                            }
                        }
                        
                    }.padding(.horizontal)
                }
            }.onAppear(perform: {
                initialize()
            })
                //.navigationTitle("Feedback")
                .navigationBarItems(trailing: student ? Button(action: {
                    self.mode.wrappedValue.dismiss()
                }, label: {
                    Text("Close")
                        .foregroundColor(Color.green)
                        .fontWeight(.bold)
                }) : Button(action: {
                    self.mode.wrappedValue.dismiss()
                }, label: {
                    Text("Save and Close")
                        .foregroundColor(Color.green)
                        .fontWeight(.bold)
                }))
        }
        
    }
}


extension UIScreen{
    static let screenWidth = UIScreen.main.bounds.size.width
    static let screenHeight = UIScreen.main.bounds.size.height
    static let screenSize = UIScreen.main.bounds.size
}

//struct StudentFeedbackView_Previews: PreviewProvider {
//    static var previews: some View {
//        StudentFeedbackView()
//    }
//}

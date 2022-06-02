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
    @State private var text: String = ""
    var student: Bool
    var uploadID: String
    @State private var showingError = false
    @State private var awaiting = true
    @State private var upload: Upload = Upload(id: -1, created: Date(), display_title: "", stream_ready: false, bucket: Bucket(id: -1, last_modified: Date(), name: ""), url: "")
    @State private var didAppear = false
    //    @State private var player = AVPlayer(url:  URL(string: "http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8")!)
    @State private var player = AVPlayer()
    
    @State private var playerDuration = 0;
    @State private var currentSeconds = 0;
    @State private var commentsAwaiting = false
    
    @State private var attributedString: AttributedString = AttributedString("")
    @State private var showingCommentEditor = false
    @State private var createCommentText = ""
    
    //    init() {
    //        //either like this:
    //        attributedString = AttributedString("Hello, #swift")
    //        let range = attributedString.range(of: "#swift")!
    //        attributedString[range].link = URL(string: "https://www.hackingwithswift.com")!
    //
    //        //or like this:
    //        attributedString = try! AttributedString(markdown: "Hello, [#swift](https://www.hackingwithswift.com)")
    //    }
    
    func initialize() async {
        do {
            awaiting = true
            print(uploadID)
            try await upload = nc.getUpload(uploadID: uploadID)
            await getComments()
            player = AVPlayer(url:  URL(string: upload.url!)!)
            //player.play()
            //player.currentItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = false
            print(upload.url!)
            print("DONE!")
            awaiting = false
        } catch {
            print(error)
            print("JSUJUS")
            showingError = true
            awaiting = false
        }
    }
    
    func getComments() async {
        do {
            commentsAwaiting = true
            try await nc.getComments(uploadID: uploadID, courtshipType: nil)
            commentsAwaiting = false
        } catch {
            print(error)
            showingError = true
            commentsAwaiting = false
        }
    }
    
    func createComment() async {
        do {
            try await nc.createComment(uploadID: uploadID, text: "$\(String(currentSeconds))$" + createCommentText)
            createCommentText = ""
            withAnimation {
                showingCommentEditor = false
            }
        } catch {
            print(error)
            showingError = true
        }
    }
    
    
    func secondsToHoursMinutesSeconds(seconds: Int) -> String {
        return "\(seconds / 3600):\((seconds % 3600) / 60):\((seconds % 3600) % 60)"
    }
    
    func returnTimestampAndText(text: String) -> (Int, String) {
        if (text.firstIndex(of: "$") != nil) {
            var mutableText = text
            mutableText.remove(at: mutableText.firstIndex(of: "$")!)
            var finalText = String(mutableText[mutableText.firstIndex(of: "$")!...])
            finalText = String(finalText.dropFirst())
            
            var timestamp = String(mutableText[...mutableText.firstIndex(of: "$")!])
            timestamp = String(timestamp.dropLast())
            
            return (Int(timestamp)!, finalText)
        }
        return (0, text)
        
    }
    
    var body: some View {
        ZStack {
            VStack(alignment: .center) {
                ScrollView {
                    VideoPlayer(player: player)
                        .frame(height: 300)
                }
                
                //Text(try! AttributedString(markdown: "Hello, [#swift](https://www.hackingwithswift.com)"))
                
                if (showingCommentEditor) {
                    //Text("Add comment at \(secondsToHoursMinutesSeconds(seconds:currentSeconds))")
                    TextEditor(text: $createCommentText)
                        .border(Color.black)
                    
                    
                } else {
                    ScrollView {
                        if (commentsAwaiting) {
                            ProgressView()
                        } else if (showingError) {
                            Text(nc.errorMessage).padding()
                        } else {
                            ScrollViewReader { proxy in
                                
                                // REGEX-ish:
                                // To represent the occurance of the comment, place ${seconds}$ at the very beginning.  e.g., to represent a comment at 00:01:15, send: "$75$my comment"
                                // To embed a timestamp in a comment, do %{seconds}%.
                                
                                
                                ForEach(nc.userData.comments.sorted(by: {returnTimestampAndText(text: $0.text).0 < returnTimestampAndText(text: $1.text).0})) { comment in
                                    if(nc.userData.shared.username == comment.author.username) {
                                        HStack {
                                            
                                            VStack(alignment: .trailing) {
                                                Text("\(comment.author.display_name) (\(comment.author.username), you)")
                                                    .foregroundColor(returnTimestampAndText(text: comment.text).0 == currentSeconds ? .green : .primary).font(.system(size: 10.0))
                                                Text((secondsToHoursMinutesSeconds(seconds: returnTimestampAndText(text: comment.text).0)))
                                                    .foregroundColor(returnTimestampAndText(text: comment.text).0 == currentSeconds ? .green : .primary).font(.system(size: 10.0))
                                                
                                                Button(action: {
                                                    currentSeconds = returnTimestampAndText(text: comment.text).0
                                                    player.seek(to: CMTimeMakeWithSeconds(Double(returnTimestampAndText(text: comment.text).0), preferredTimescale: 1))
                                                }, label: {
                                                    Text(returnTimestampAndText(text: comment.text).1)
                                                        .foregroundColor(/*returnTimestampAndText(text: comment.text).0 == currentSeconds ? .green : .primary*/.white)
                                                })
                                                //.frame(maxWidth: .infinity)
                                                .background(Color.green)
                                                .cornerRadius(10)
                                                .foregroundColor(.white)
                                                
                                                
                                            }
                                        }
                                    } else {
                                        HStack {
                                            VStack {
                                                Text("\(comment.author.display_name) (\(comment.author.username))")
                                                    .foregroundColor(returnTimestampAndText(text: comment.text).0 == currentSeconds ? .green : .primary).font(.system(size: 10.0)).padding([.bottom, .top], 10)
                                                
                                                Button(action: {
                                                    currentSeconds = returnTimestampAndText(text: comment.text).0
                                                    player.seek(to: CMTimeMakeWithSeconds(Double(returnTimestampAndText(text: comment.text).0), preferredTimescale: 1))
                                                }, label: {
                                                    Text(returnTimestampAndText(text: comment.text).1)
                                                        .foregroundColor(returnTimestampAndText(text: comment.text).0 == currentSeconds ? .green : .primary)
                                                })
                                                .padding(.vertical, 15)
                                                .frame(maxWidth: .infinity)
                                                .cornerRadius(10)
                                                .foregroundColor(.white)
                                                
                                                
                                            }
                                            Text((secondsToHoursMinutesSeconds(seconds: returnTimestampAndText(text: comment.text).0)))
                                                .foregroundColor(returnTimestampAndText(text: comment.text).0 == currentSeconds ? .green : .primary).font(.system(size: 10.0)).padding([.leading,.trailing, .bottom, .top], 20)
                                        }
                                    }
                                }
                                
                                .onChange(of: currentSeconds) { value in
                                    withAnimation {
                                        proxy.scrollTo(value, anchor: .top)
                                    }
                                }
                            }
                        }
                    }
//                    .onAppear(perform: {
//                        DispatchQueue.main.async {
//                            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { _ in
//                                // Hack to fix concurrency issue at the beginning
//                                if (!player.currentItem!.duration.seconds.isNaN) {
//                                    withAnimation {
//                                        playerDuration = Int(player.currentItem!.duration.seconds)
//                                    }
//                                    
//                                }
//                                
//                                currentSeconds = Int(player.currentTime().seconds)
//                            })
//                        }
//                    })
                }
                
                
                HStack {
                    if (!showingCommentEditor) {
                        Spacer()
                    }
                    
                    
                    if (showingCommentEditor) {
                        Button(action: {
                            Task {
                                await createComment()
                            }
                            
                            //                                withAnimation {
                            //                                    showingCommentEditor.toggle()
                            //                                }
                        }, label: {
                            Text("Add comment at \(secondsToHoursMinutesSeconds(seconds:currentSeconds))")
                                .buttonStyle()
                        })
                        
                    }
                    
                    
                    Button(action: {
                        player.pause()
                        withAnimation {
                            showingCommentEditor.toggle()
                        }
                    }, label: {
                        Image(systemName: !showingCommentEditor ? "plus.circle.fill" : "x.circle.fill")
                            .resizable()
                            .scaledToFill()
                            .foregroundColor(!showingCommentEditor ? Color.green : Color.red)
                            .frame(width: 40, height: 40)
                        
                    })
                    
                }
                .padding(.bottom)
                
                
//                Text(text)
//                    .multilineTextAlignment(.leading)
//
//                Text("Unsaved changes")
//                    .font(.footnote)
//                    .foregroundColor(Color.red)
//
//                TextEditor(text: $text)
//                    .padding(1)
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 5)
//                            .stroke(Color.gray, lineWidth: 1)
//                    )
//                    .frame(minHeight: UIScreen.screenHeight - 200)
                
                
                
            }.padding(.horizontal)
            
        }.task {
            await initialize()
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

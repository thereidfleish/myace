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
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = (seconds % 3600) % 60
        let HH = (h < 9 ? "0" : "") + String(h)
        let MM = (m < 9 ? "0" : "") + String(m)
        let SS = (s < 9 ? "0" : "") + String(s)
        return "\(HH):\(MM):\(SS)"
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
                                    
                                    let isYou: Bool = nc.userData.shared.username == comment.author.username
                                    
                                    VStack(alignment: isYou ? .trailing : .leading) {
                                        Text("\(comment.author.display_name) (\((secondsToHoursMinutesSeconds(seconds: returnTimestampAndText(text: comment.text).0))))")
                                            .foregroundColor(returnTimestampAndText(text: comment.text).0 == currentSeconds ? .green : .primary).font(.system(size: 10.0))
                                        
                                        Button(action: {
                                            currentSeconds = returnTimestampAndText(text: comment.text).0
                                            player.seek(to: CMTimeMakeWithSeconds(Double(returnTimestampAndText(text: comment.text).0), preferredTimescale: 1))
                                        }, label: {
                                            Text(returnTimestampAndText(text: comment.text).1)
                                                .foregroundColor(/*returnTimestampAndText(text: comment.text).0 == currentSeconds ? .green : .primary*/.white)
                                                .multilineTextAlignment(.leading)
                                        })
                                        .padding(7)
                                        .background(isYou ? Color.green : Color.gray)
                                        .cornerRadius(7)
                                        .foregroundColor(.white)
                                        .contextMenu {
                                            Group {
                                                Button(role: .destructive, action: {
                                                    Task {
                                                        try await nc.deleteComment(commentID: String(comment.id))
                                                        await initialize()
                                                    }
                                                }, label: {
                                                    Label("Delete", systemImage: "trash")
                                                })
                                            }
                                        }
                                        
                                        
                                    }
                                    .id(returnTimestampAndText(text: comment.text).0)
                                    .padding(.bottom)
                                    //.padding(isYou ? .leading : .trailing, 10)
                                    .frame(maxWidth: .greatestFiniteMagnitude, alignment: isYou ? .trailing : .leading)
                                    
                                    
                                    
                                }
                                
                                .onChange(of: currentSeconds) { value in
                                    print(value)
                                    withAnimation {
                                        proxy.scrollTo(value, anchor: .top)
                                    }
                                }
                            }
                        }
                    }
                    .onAppear(perform: {
                        DispatchQueue.main.async {
                            Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true, block: { _ in
                                // Hack to fix concurrency issue at the beginning
                                let currentItem = player.currentItem
                                if (currentItem != nil) {
                                    //                                    if (!currentItem!.duration.seconds.isNaN) {
                                    //                                        withAnimation {
                                    //                                            playerDuration = Int(player.currentItem!.duration.seconds)
                                    //                                        }
                                    //
                                    //                                    }
                                    currentSeconds = Int(player.currentTime().seconds)
                                }
                                
                                
                                
                            })
                        }
                    })
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

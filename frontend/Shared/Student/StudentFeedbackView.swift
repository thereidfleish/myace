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
    @State var text: String
    var student: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    VideoPlayer(player: AVPlayer(url:  URL(string: "https://appdev-backend-final.s3.us-east-2.amazonaws.com/hls/RFvsNadal_full_point_0.fmp4/index.m3u8")!))
                        .frame(height: 400)
                    
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
                    
                }.padding(.horizontal)
            }.navigationTitle("Feedback")
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

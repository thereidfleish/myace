//
//  StudentVideoView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/27/21.
//

import SwiftUI
import AVKit

struct StudentVideoView: View {
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    var student: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    VideoPlayer(player: AVPlayer(url:  URL(string: "http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8")!))
                        .frame(height: 400)
                    if (student) {
                        
                    }
                    else {
                        
                        
                    }
                    
                }.padding(.horizontal)
            }.navigationTitle("View Video")
                .navigationBarItems(trailing: Button("Close") {
                    self.mode.wrappedValue.dismiss()
                })
        }
    }
}

//struct StudentVideoView_Previews: PreviewProvider {
//    static var previews: some View {
//        StudentVideoView()
//    }
//}

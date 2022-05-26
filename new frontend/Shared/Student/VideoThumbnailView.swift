//
//  VideoThumbnailView.swift
//  AI Tennis Coach
//
//  Created by AndrewC on 5/26/22.
//

import SwiftUI

struct VideoThumbnailView: View {
    var upload: Upload
    var body: some View {
        NavigationLink(destination: StudentFeedbackView(text: "SJ", student: true, showOnlyVideo: true, uploadID: "\(upload.id)").navigationTitle("Feedback").navigationBarTitleDisplayMode(.inline))
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
                .frame(maxWidth: 200, maxHeight: 150)
                .cornerRadius(10)
                .shadow(radius: 5)
                
            }
            
        }.disabled(!upload.stream_ready)
            .padding([.trailing], 5)
    }
}

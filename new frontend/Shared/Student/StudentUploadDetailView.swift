//
//  StudentUploadDetailView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/22/21.
//

import SwiftUI
import MediaPicker
import Alamofire
//import AVKit



struct StudentUploadDetailView: View {
    @EnvironmentObject private var nc: NetworkController
    @State private var showingFeedback = false
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    
    @State private var showOnlyVideo = false
    
    @State private var isShowingMediaPicker = false
    @State private var isShowingCamera = false
    @State var url: [URL] = []
    @State private var originalName = ""
    var otherUser: SharedData
    var currentUserAs: CurrentUserAs
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var awaiting = false
    @State private var uploading = false
    @State private var uploadingStatus = ""
    @State private var progressPercent = ""
    @State private var showsUploadAlert = false
    @State private var uploadName = ""
    @State private var showingEditingName = false
    @State private var showingEditingNameUploadID: String = ""
    @State private var showingDelete = false
    @State private var showingDeleteUploadID: String = ""
    @State private var currentBucketID: Int = -1
    
    func initialize() async {
        do {
            awaiting = true
//            print("getting buckets1")
//            try await nc.getBuckets(userID: coach ? String(otherUser.id) : String(nc.userData.shared.id))
//            print("getting uploads1")
//            try await nc.getUploads(shared_with_ID: coach ? otherUser.id : nil, bucketID: nil)
            //try await nc.getUploads(getSpecificID: true, bucketID: bucketID)
            print("Finsihed init")
            awaiting = false
        } catch {
            print(error)
            errorMessage = error.localizedDescription
            showingError = true
            awaiting = false
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                StrokesView(otherUser: otherUser, currentUserAs: currentUserAs)

                
            }.padding(.horizontal)
            
        }
        .task {
            await initialize()
        }
        
        
        
        
    }
}

//struct StudentUploadDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        StudentUploadDetailView()
//    }
//}

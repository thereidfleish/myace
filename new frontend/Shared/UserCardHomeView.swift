//
//  UserCardView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 1/23/22.
//

import SwiftUI

struct UserCardHomeView: View {
    @EnvironmentObject private var nc: NetworkController
    @State private var awaiting = false
    @State private var showingStatus = false
    @State private var statusMessage = ""
    @State var user: SharedData
    
    var body: some View {
        
        VStack {
            HStack {
                NavigationLink(destination: StudentUploadDetailView(otherUser: user).navigationTitle(user.display_name).navigationBarTitleDisplayMode(.inline))
                {
                    VStack(alignment: .leading) {
                        Text(user.display_name)
                            .bucketNameStyle()
                            .foregroundColor(Color.white)
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(Color.white)
                                .frame(width: 15)
                            Text("@\(user.username)")
                                .bucketTextExternalStyle()
                        }
                        
                        HStack {
                            Image(systemName: "text.bubble.fill")
                                .foregroundColor(.white)
                                .frame(width: 15)
                            if (/*studentInfo.numFeedback[i]*/ 0 == 0) {
                                Text(/*"\(studentInfo.numFeedback[i])*/ "New Feedback")
                                    .bucketTextExternalStyle()
                            }
                            else {
                                Text(/*"*\(studentInfo.numFeedback[i])*/ "New Feedback")
                                    .unreadBucketTextExternalStyle()
                            }
                            
                        }
                        
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.white)
                                .frame(width: 15)
                            
                            Text("last modified here")
                                .bucketTextExternalStyle()
                        }

                    }
                    
                    Spacer()
                }
                
                
            }
        }.navigationLinkStyle()
        
    }
}

//struct UserCardView_Previews: PreviewProvider {
//    static var previews: some View {
//        UserCardView()
//    }
//}

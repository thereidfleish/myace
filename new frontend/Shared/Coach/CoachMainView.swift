////
////  CoachMainView.swift
////  AI Tennis Coach
////
////  Created by Reid Fleishman on 12/25/21.
////
//
//import SwiftUI
//
//struct CoachMainView: View {
//    
//    @EnvironmentObject var coachInfo: CoachInfo
//    
//    var body: some View {
//        NavigationView {
//            ScrollView {
//                VStack(alignment: .leading) {
//                    Text("\(UserData.computeWelcome()) Reid!")
//                        .bucketNameStyle()
//                        .foregroundColor(Color.green)
//                        .padding(.horizontal)
//                    
//                    ForEach(coachInfo.studentNames.indices, id: \.self) { i in
//                        NavigationLink(destination: CoachStudentView(name: coachInfo.studentNames[i]).navigationTitle(coachInfo.studentNames[i]).navigationBarTitleDisplayMode(.inline))
//                        {
//                            HStack {
//                                VStack(alignment: .leading) {
//                                    Text(coachInfo.studentNames[i])
//                                        .bucketNameStyle()
//                                        .foregroundColor(Color.white)
//                                    
//                                    HStack {
//                                        Image(systemName: "video.fill")
//                                            .foregroundColor(.white)
//                                            .frame(width: 15)
//                                        if (coachInfo.numNewVideos[i] == 0) {
//                                            Text("\(coachInfo.numNewVideos[i]) New Uploads")
//                                                .bucketTextExternalStyle()
//                                        }
//                                        else {
//                                            Text("*\(coachInfo.numNewVideos[i]) New Uploads")
//                                                .unreadBucketTextExternalStyle()
//                                        }
//                                        
//                                    }
//                                    
//                                    HStack {
//                                        Image(systemName: "clock.fill")
//                                            .foregroundColor(.white)
//                                            .frame(width: 15)
//                                        Text(coachInfo.modifyDates[i])
//                                            .bucketTextExternalStyle()
//                                    }
//                                }
//                                
//                                Spacer()
//                                
//                                Image(systemName: "chevron.right.square.fill")
//                                    .resizable()
//                                    .scaledToFill()
//                                    .foregroundColor(Color.white)
//                                    .frame(width: 20, height: 20)
//                            }
//                            .navigationLinkStyle()
//                        }
//                    }
//                }
//                
//            }.navigationTitle("Students"/*, displayMode: .inline*/)
//        }
//    }
//}
//
////struct CoachMainView_Previews: PreviewProvider {
////    static var previews: some View {
////        CoachMainView()
////    }
////}

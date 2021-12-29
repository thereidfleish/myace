//
//  CoachStudentView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/26/21.
//

import SwiftUI

struct CoachStudentView: View {
    @State var name: String
    @EnvironmentObject var coachInfo: CoachInfo
    
    var body: some View {
        ScrollView {
            ForEach(coachInfo.strokes.indices, id: \.self) { i in
                NavigationLink(destination: StudentUploadDetailView(name: coachInfo.strokes[i], student: false).navigationTitle(coachInfo.strokes[i]).navigationBarTitleDisplayMode(.inline))
                {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(coachInfo.strokes[i])
                                .font(.title2)
                                .fontWeight(.heavy)
                                .foregroundColor(Color.white)
                            
                            HStack {
                                Image(systemName: "video.fill")
                                    .foregroundColor(.white)
                                    .frame(width: 15)
                                if (coachInfo.numNewVideos2[i] == 0) {
                                    Text("\(coachInfo.numNewVideos2[i]) New Uploads")
                                        .font(.subheadline)
                                        .foregroundColor(Color.white)
                                }
                                else {
                                    Text("*\(coachInfo.numNewVideos2[i]) New Uploads")
                                        .font(.subheadline)
                                        .bold()
                                        .foregroundColor(Color.white)
                                }
                                
                            }
                            
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(.white)
                                    .frame(width: 15)
                                Text(coachInfo.modifyDates2[i])
                                    .font(.subheadline)
                                    .foregroundColor(Color.white)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right.square.fill")
                            .resizable()
                            .scaledToFill()
                            .foregroundColor(Color.white)
                            .frame(width: 20, height: 20)
                    }
                    .padding()
                    .background(Color.green)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    .shadow(radius: 5)
                }
            }
        }
    }
}

//struct CoachStudentView_Previews: PreviewProvider {
//    static var previews: some View {
//        CoachStudentView()
//    }
//}

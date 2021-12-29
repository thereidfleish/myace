//
//  CoachMainView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/25/21.
//

import SwiftUI

struct CoachMainView: View {
    let data: UserData
    @EnvironmentObject var coachInfo: CoachInfo
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("\(UserData.computeWelcome()) Reid!")
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundColor(Color.green)
                        .padding(.horizontal)
                    
                    ForEach(coachInfo.studentNames.indices, id: \.self) { i in
                        NavigationLink(destination: CoachStudentView(name: coachInfo.studentNames[i]).navigationTitle(coachInfo.studentNames[i]).navigationBarTitleDisplayMode(.inline))
                        {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(coachInfo.studentNames[i])
                                        .font(.title2)
                                        .fontWeight(.heavy)
                                        .foregroundColor(Color.white)
                                    
                                    HStack {
                                        Image(systemName: "video.fill")
                                            .foregroundColor(.white)
                                            .frame(width: 15)
                                        if (coachInfo.numNewVideos[i] == 0) {
                                            Text("\(coachInfo.numNewVideos[i]) New Uploads")
                                                .font(.subheadline)
                                                .foregroundColor(Color.white)
                                        }
                                        else {
                                            Text("*\(coachInfo.numNewVideos[i]) New Uploads")
                                                .font(.subheadline)
                                                .bold()
                                                .foregroundColor(Color.white)
                                        }
                                        
                                    }
                                    
                                    HStack {
                                        Image(systemName: "clock.fill")
                                            .foregroundColor(.white)
                                            .frame(width: 15)
                                        Text(coachInfo.modifyDates[i])
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
                
            }.navigationTitle("Students"/*, displayMode: .inline*/)
        }
    }
}

//struct CoachMainView_Previews: PreviewProvider {
//    static var previews: some View {
//        CoachMainView()
//    }
//}

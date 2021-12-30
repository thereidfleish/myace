//
//  StudentUploadView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/22/21.
//

import SwiftUI

struct StudentUploadView: View {
    let data: UserData
    @EnvironmentObject var studentInfo: StudentInfo
    @State private var showingNewBucketView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                //                Button(action: {
                //
                //                }, label: {
                //                    Text("Create New Stroke")
                //                        .padding(.vertical, 15)
                //                        .frame(maxWidth: .infinity)
                //                        .background(Color.green)
                //                        .cornerRadius(10)
                //                        .foregroundColor(.white)
                //                })
                //                    .padding([.horizontal, .top, .bottom])
                
                VStack(alignment: .leading) {
                    Text("\(UserData.computeWelcome()) \(data.shared.display_name)")
                        .font(.title2)
                        .fontWeight(.heavy)
                        .foregroundColor(Color.green)
                        .padding(.horizontal)
                    
                    ForEach(studentInfo.strokeNames.indices, id: \.self) { i in
                        NavigationLink(destination: StudentUploadDetailView(name: studentInfo.strokeNames[i], student: true).navigationTitle(studentInfo.strokeNames[i]).navigationBarTitleDisplayMode(.inline))
                        {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(studentInfo.strokeNames[i])
                                        .font(.title2)
                                        .fontWeight(.heavy)
                                        .foregroundColor(Color.white)
                                    
                                    HStack {
                                        Image(systemName: "person.fill")
                                            .foregroundColor(Color.white)
                                            .frame(width: 15)
                                        Text(studentInfo.trainerNames[i])
                                            .font(.subheadline)
                                            .foregroundColor(Color.white)
                                    }
                                    
                                    HStack {
                                        Image(systemName: "text.bubble.fill")
                                            .foregroundColor(.white)
                                            .frame(width: 15)
                                        if (studentInfo.numFeedback[i] == 0) {
                                            Text("\(studentInfo.numFeedback[i]) New Feedback")
                                                .font(.subheadline)
                                                .foregroundColor(Color.white)
                                        }
                                        else {
                                            Text("*\(studentInfo.numFeedback[i]) New Feedback")
                                                .font(.subheadline)
                                                .bold()
                                                .foregroundColor(Color.white)
                                        }
                                        
                                    }
                                    
                                    HStack {
                                        Image(systemName: "clock.fill")
                                            .foregroundColor(.white)
                                            .frame(width: 15)
                                        Text(studentInfo.modifyDates[i])
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
                    }.sheet(isPresented: $showingNewBucketView) {
                        NewBucketView()
                        
                    }
                    
                }
            }.navigationTitle("Uploads"/*, displayMode: .inline*/)
                .navigationBarItems(trailing: Button(action: {
                    showingNewBucketView.toggle()
                }, label: {
                    Text("Add Stroke")
                        .foregroundColor(Color.green)
                        .fontWeight(.bold)
                }))
        }
    }
}


//struct StudentUploadView_Previews: PreviewProvider {
//    static var previews: some View {
//        StudentUploadView()
//    }
//}

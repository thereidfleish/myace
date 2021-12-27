//
//  StudentUploadDetailView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/22/21.
//

import SwiftUI

struct StudentUploadDetailView: View {
    @EnvironmentObject var studentInfo: StudentInfo
    @State private var showingFeedback = false
    @State var name: String
    @State var student: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Name")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .padding([.top, .leading, .trailing])
                
                TextField("Name", text: $name)
                    .autocapitalization(.none)
                    .padding(.horizontal)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                if (student) {
                Button(action: {
                    print("uploading...")
                }, label: {
                    Text("Upload New Video")
                        .padding(.vertical, 15)
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                        .foregroundColor(.white)
                    //.opacity(subject != subjectText ? 1 : 0.75)
                })
                //.disabled(subject == subjectText ? true : false)
                    .padding([.horizontal, .top, .bottom])
                }
                
                ForEach(studentInfo.strokeNames.indices, id: \.self) { i in
                    HStack {
                        Button(action: {
                            print("video...")
                        }, label: {
                            Image("testimage")
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: 200, maxHeight: 200)
                                .cornerRadius(10)
                                .shadow(radius: 5)
                        })
                        
                        
                        VStack(alignment: .leading) {
                            Text(studentInfo.modifyDates2[i])
                                .font(.title2)
                                .fontWeight(.heavy)
                                .foregroundColor(Color.green)
                            
                            Button(action: {
                                showingFeedback.toggle()
                            }, label: {
                                if (studentInfo.feedbacks[i] == .awaiting) {
                                    Image(systemName: student ? "person.crop.circle.badge.clock.fill" : "note.text.badge.plus")
                                        .resizable()
                                        .scaledToFill()
                                        .foregroundColor(student ? Color.gray: Color.green)
                                        .frame(width: 25, height: 25)
                                        .opacity(student ? 0.5 : 1)
                                }
                                if (studentInfo.feedbacks[i] == .unread) {
                                    Image(systemName: student ? "text.bubble.fill" : "note.text")
                                        .resizable()
                                        .scaledToFill()
                                        .foregroundColor(Color.green)
                                        .frame(width: 25, height: 25)
                                }
                                if (studentInfo.feedbacks[i] == .read) {
                                    Image(systemName: student ? "text.bubble.fill" : "note.text")
                                        .resizable()
                                        .scaledToFill()
                                        .foregroundColor(Color.gray)
                                        .frame(width: 25, height: 25)
                                }
                                
                            })
                                .disabled(studentInfo.feedbacks[i] == .awaiting && student ? true : false)
                            
                            Spacer()
                            
                            Text("\(studentInfo.times[i]) | \(studentInfo.sizes[i])")
                                .font(.footnote)
                                .foregroundColor(Color.green)
                            
                        }.padding(.leading, 1)
                    }
                    .padding(.horizontal)
                }
            }.sheet(isPresented: $showingFeedback) {
                StudentFeedbackView(text: "This is some sample feedback", student: student)
            }
            
            
        }.navigationBarItems(
            trailing:
                Button("Save") {
                    print("save")
                }
        )
    }
}

//struct StudentUploadDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        StudentUploadDetailView()
//    }
//}

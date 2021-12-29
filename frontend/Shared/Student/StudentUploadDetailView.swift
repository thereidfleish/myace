//
//  StudentUploadDetailView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/22/21.
//

import SwiftUI
import MediaPicker

struct StudentUploadDetailView: View {
    @EnvironmentObject var studentInfo: StudentInfo
    @State private var showingFeedback = false
    @State private var showingVideo = false
    @State private var isShowingMediaPicker = false
    @State private var url: [URL] = []
    @State var name: String
    @State private var originalName = ""
    @State var student: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Name")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.green)
                    .padding([.top, .leading, .trailing])
                
                HStack {
                    TextField("Name", text: $name)
                        .autocapitalization(.none)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onAppear(perform: {
                        self.originalName = name
                    })
                    
                    Button(action: {
                        print("save")
                        originalName = name
                    }, label: {
                        Text("Save")
                            .foregroundColor(name == originalName ? Color.gray : Color.green)
                            .fontWeight(.bold)
                    })
                        .disabled(name == originalName)
                }.padding(.horizontal)
                
                if (student) {
                    Button(action: {
                        isShowingMediaPicker.toggle()
                    }, label: {
                        Text("Upload New Video")
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    })
                        .padding([.horizontal, .top, .bottom])
                        .mediaImporter(isPresented: $isShowingMediaPicker,
                                       allowedMediaTypes: .all,
                                       allowsMultipleSelection: false) { result in
                            switch result {
                            case .success(let url):
                                self.url = url
                                print(url)
                            case .failure(let error):
                                print(error)
                                self.url = []
                            }
                        }
                }
                
                ForEach(studentInfo.strokeNames.indices, id: \.self) { i in
                    HStack {
                        Button(action: {
                            showingVideo.toggle()
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
                                    Image(systemName: student ? "person.crop.circle.badge.clock.fill" : "plus.bubble.fill")
                                        .resizable()
                                        .scaledToFill()
                                        .foregroundColor(student ? Color.gray: Color.green)
                                        .frame(width: 25, height: 25)
                                        .opacity(student ? 0.5 : 1)
                                }
                                if (studentInfo.feedbacks[i] == .unread) {
                                    Image(systemName: "text.bubble.fill")
                                        .resizable()
                                        .scaledToFill()
                                        .foregroundColor(Color.green)
                                        .frame(width: 25, height: 25)
                                }
                                if (studentInfo.feedbacks[i] == .read) {
                                    Image(systemName: "text.bubble.fill")
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
            .sheet(isPresented: $showingVideo) {
                StudentVideoView(student: student)
            }
            
        }
    }
}

//struct StudentUploadDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        StudentUploadDetailView()
//    }
//}

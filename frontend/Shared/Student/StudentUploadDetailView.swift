//
//  StudentUploadDetailView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/22/21.
//

import SwiftUI

struct StudentUploadDetailView: View {
    @State private var showingFeedback = false
    @State var name: String;
    
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
                        Text("12/22/21")
                            .font(.title2)
                            .fontWeight(.heavy)
                            .foregroundColor(Color.green)
                        
                        Button(action: {
                            showingFeedback.toggle()
                        }, label: {
                            Image(systemName: "person.crop.circle.badge.clock.fill")
                                .resizable()
                                .scaledToFill()
                                .foregroundColor(Color.gray)
                                .frame(width: 25, height: 25)
                                .opacity(0.5)
                        })
                            .disabled(true)
                        
                        Spacer()
                        
                        Text("12:18 | 3.3 GB")
                            .font(.footnote)
                            .foregroundColor(Color.green)
                        
                    }.padding(.leading, 1)
                }
                .padding(.horizontal)
                
                
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
                        Text("12/21/21")
                            .font(.title2)
                            .fontWeight(.heavy)
                            .foregroundColor(Color.green)
                        
                        Button(action: {
                            showingFeedback.toggle()
                        }, label: {
                            Image(systemName: "text.bubble.fill")
                                .resizable()
                                .scaledToFill()
                                .foregroundColor(Color.green)
                                .frame(width: 25, height: 25)
                            
                            //.opacity(subject != subjectText ? 1 : 0.75)
                        })
                        //.disabled(subject == subjectText ? true : false)
                        
                        Spacer()
                        
                        Text("1:18 | 254 MB")
                            .font(.footnote)
                            .foregroundColor(Color.green)
                        
                    }.padding(.leading, 1)
                }
                .padding(.horizontal)
                
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
                        Text("12/20/21")
                            .font(.title2)
                            .fontWeight(.heavy)
                            .foregroundColor(Color.green)
                        
                        Button(action: {
                            showingFeedback.toggle()
                        }, label: {
                            Image(systemName: "text.bubble.fill")
                                .resizable()
                                .scaledToFill()
                                .foregroundColor(Color.gray)
                                .frame(width: 25, height: 25)
                            //.opacity(0.5)
                        })
                            .disabled(false)
                        
                        Spacer()
                        
                        Text("1:10 | 263.8 MB")
                            .font(.footnote)
                            .foregroundColor(Color.green)
                        
                    }.padding(.leading, 1)
                }
                .padding(.horizontal)
                
                
                
            }.sheet(isPresented: $showingFeedback) {
                StudentFeedbackView(text: "This is some sample feedback")
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

//
//  StudentUploadView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/22/21.
//

import SwiftUI

struct StudentUploadView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                NavigationLink(destination: StudentUploadDetailView(name: "Backhand Groundstroke").navigationTitle("Backhand Groundstroke").navigationBarTitleDisplayMode(.inline))
                {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Backhand Groundstroke")
                            .font(.title2)
                            .fontWeight(.heavy)
                            .foregroundColor(Color.white)
                        
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(Color.white)
                                .frame(width: 15)
                            Text("Trainer Name")
                                .font(.subheadline)
                                .foregroundColor(Color.white)
                        }
                        
                        HStack {
                            Image(systemName: "text.bubble.fill")
                                .foregroundColor(.white)
                                .frame(width: 15)
                            Text("0 New Feedback")
                                .font(.subheadline)
                                .foregroundColor(Color.white)
                        }
                        
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.white)
                                .frame(width: 15)
                            Text("12/22/21")
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
                
                NavigationLink(destination: StudentUploadDetailView(name: "Forehand Groundstroke").navigationTitle("Forehand Groundstroke").navigationBarTitleDisplayMode(.inline))
                {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Forehand Groundstroke")
                            .font(.title2)
                            .fontWeight(.heavy)
                            .foregroundColor(Color.white)
                        
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(Color.white)
                                .frame(width: 15)
                            Text("Trainer Name")
                                .font(.subheadline)
                                .foregroundColor(Color.white)
                        }
                        
                        HStack {
                            Image(systemName: "text.bubble.fill")
                                .foregroundColor(.white)
                                .frame(width: 15)
                            Text("*1 New Feedback")
                                .font(.subheadline)
                                .bold()
                                .foregroundColor(Color.white)
                        }
                        
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(.white)
                                .frame(width: 15)
                            Text("12/22/21")
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
            }.navigationTitle("Uploads"/*, displayMode: .inline*/)
        }
    }
}

struct StudentUploadView_Previews: PreviewProvider {
    static var previews: some View {
        StudentUploadView()
    }
}

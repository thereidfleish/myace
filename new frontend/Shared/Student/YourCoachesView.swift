//
//  YourCoachesView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/22/21.
//

import SwiftUI

struct StudentUploadView: View {
    @EnvironmentObject private var nc: NetworkController
    @State private var showingNewBucketView = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var awaiting = false
    @State var didAppear = false
    
    func initialize() {
        if (!didAppear) {
            didAppear = true
            Task {
                do {
                    awaiting = true
                    try await nc.getBuckets()
                    awaiting = false
                    print("DONE!")
                } catch {
                    print(error)
                    errorMessage = error.localizedDescription
                    showingError = true
                    awaiting = false
                }
                
                print(nc.userData.buckets)
            }
        }
        
    }
    
    var body: some View {
        
        NavigationView {
            VStack {
                if (awaiting) {
                    ProgressView()
                } else if (showingError) {
                    Text(Helper.computeErrorMessage(errorMessage: errorMessage)).padding()
                } else {
                    GeometryReader { geometry in
                        VStack(alignment: .leading) {
                            Text("\(Helper.computeWelcome()) \(Helper.firstName(name: nc.userData.shared.display_name))!")
                                .bucketNameStyle()
                                .foregroundColor(Color.green)
                                .padding(.bottom, 5)
                            
                            Text("Your Coaches")
                                .sectionHeadlineStyle()
                                .foregroundColor(Color.green)
                                .padding(.bottom, -5)
                            
                            ScrollView {
                                ForEach(nc.userData.buckets) { bucket in
                                    UserCardHomeView(user: SharedData(id: -1, username: "", display_name: ""), bucket: bucket)
                                }
                            }.frame(height: geometry.size.height/2.5)
                            
                            Text("Your Students")
                                .sectionHeadlineStyle()
                                .foregroundColor(Color.green)
                                .padding(.top, 5)
                                .padding(.bottom, -5)
                            
                            ScrollView {
                                ForEach(nc.userData.buckets) { bucket in
                                    UserCardHomeView(user: SharedData(id: -1, username: "", display_name: ""), bucket: bucket)
                                }
                            }.frame(height: geometry.size.height/2.5)
                            
                        }.sheet(isPresented: $showingNewBucketView) {
                            NewBucketView()
                            
                        }
                    
                    }
                }
                
            }.padding(.horizontal)
                .onAppear(perform: {initialize()})
                .navigationBarTitle("Home", displayMode: .inline)
                .navigationBarItems(leading: Button(action: {
                    didAppear = false
                    initialize()
                }, label: {
                    Image(systemName: "arrow.clockwise.circle.fill")
                        .foregroundColor(Color.green)
                }),trailing: Button(action: {
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

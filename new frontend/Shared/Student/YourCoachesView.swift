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
    
    //@State private var coaches: [Courtship] = []
    
//    lazy var load: () -> Void = {
//        do {
//            awaiting = true
//            try await nc.getCourtships(type: nil, users: nil)
//            awaiting = false
//            print("DONE!")
//        } catch {
//            print(error)
//            errorMessage = error.localizedDescription
//            showingError = true
//            awaiting = false
//        }
//    }()
    
    func initialize() {
        if (!didAppear) {
            didAppear = true
            Task {
                do {
                    awaiting = true
                    try await nc.getCourtships(type: nil, users: nil)
                    awaiting = false
                    print("DONE!")
                } catch {
                    print(error)
                    errorMessage = error.localizedDescription
                    showingError = true
                    awaiting = false
                }
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
                        VStack(alignment: .leading) {
                            Text("\(Helper.computeWelcome()) \(Helper.firstName(name: nc.userData.shared.display_name))!")
                                .bucketNameStyle()
                                .foregroundColor(Color.green)
                            
                            Text("Your Coaches")
                                .sectionHeadlineStyle()
                                .foregroundColor(Color.green)
                            
                            ScrollView {
                                ForEach(nc.userData.courtships.filter {$0.type == .coach}, id: \.self.user.id) { coach in
                                    UserCardHomeView(user: coach.user)
                                }
                            }
                            
                        }.sheet(isPresented: $showingNewBucketView) {
                            NewBucketView()
                            
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
                .refreshable {
                    do {
                        try await nc.getCourtships(type: nil, users: nil)
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                    
                }
        }
    }
}


//struct StudentUploadView_Previews: PreviewProvider {
//    static var previews: some View {
//        StudentUploadView()
//    }
//}

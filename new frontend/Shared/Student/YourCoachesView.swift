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
    @State private var filteredCourtships: [Courtship] = []
    
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
    
    //    func initialize() {
    //        if (!didAppear) {
    //            didAppear = true
    //            Task {
    //                do {
    //                    awaiting = true
    //                    try await nc.getCourtships(type: nil, users: nil)
    //                    awaiting = false
    //                    print("DONE!")
    //                } catch {
    //                    print(error)
    //                    errorMessage = error.localizedDescription
    //                    showingError = true
    //                    awaiting = false
    //                }
    //            }
    //        }
    //
    //    }
    
    func initialize() async {
        do {
            awaiting = true
            try await nc.getCourtships(type: nil, users: nil)
            filteredCourtships = nc.userData.courtships.filter {$0.type == .coach}
            awaiting = false
            print("DONE!")
        } catch {
            print(error)
            errorMessage = error.localizedDescription
            showingError = true
            awaiting = false
        }
    }
    
    var body: some View {
        
        NavigationView {
            VStack {
                
                VStack(alignment: .leading) {
                    Text("\(Helper.computeWelcome()) \(Helper.firstName(name: nc.userData.shared.display_name))!")
                        .bucketNameStyle()
                        .foregroundColor(Color.green)
                    
                    Text("Your Coaches")
                        .sectionHeadlineStyle()
                        .foregroundColor(Color.green)
                    
                    if filteredCourtships.isEmpty {
                        Text("Welcome!  To get started, use the search bar to search for some coaches.  Once they have accepted your courtship requests, they will appear here.")
                            .multilineTextAlignment(.center)
                            .padding(.top)
                    }
                    
                    ScrollView {
                        ForEach(filteredCourtships, id: \.self.user.id) { coach in
                            UserCardHomeView(user: coach.user)
                        }
                    }
                    
                }.sheet(isPresented: $showingNewBucketView) {
                    NewBucketView()
                    
                }
                
                
                
                
            }.padding(.horizontal)
            //                .onAppear {
            //                    await initialize()
            //                }
                .task {
                    await initialize()
                }
                .navigationBarTitle("Home", displayMode: .inline)
                .navigationBarItems(leading: Refresher().refreshable {
                    await initialize()
                },trailing: Button(action: {
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

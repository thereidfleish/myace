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
    var currentUserAs: CurrentUserAs
    
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
            try await nc.getCourtships(user_id: "me", type: currentUserAs == .student ? CourtshipType.coach : CourtshipType.student)
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
                    
                    Text(currentUserAs == .coach ? "Your Students" : "Your Coaches")
                        .sectionHeadlineStyle()
                        .foregroundColor(Color.green)
                    
                    if nc.userData.courtships.isEmpty {
                        Text("Welcome!  To get started, use the search bar to search for some \(currentUserAs == .coach ? "students" : "coaches").  Once they have accepted your courtship requests, they will appear here.")
                            .multilineTextAlignment(.center)
                            .padding(.top)
                    }
                    
                    
                    ScrollView {
                        if(awaiting) {
                            ProgressView()
                        }
                        else if(showingError) {
                            Text(nc.errorMessage).padding()
                        }
                        else {
                            ForEach(nc.userData.courtships, id: \.self.id) { user in
                                UserCardHomeView(user: user, currentUserAs: currentUserAs)
                            }
                        }
                    }
                    
                    
                }.sheet(isPresented: $showingNewBucketView) {
                    NewBucketView()
                    
                }
                
                
                
                
            }.padding(.horizontal)
                .navigationBarTitle("Home", displayMode: .inline)
                .navigationBarItems(leading: Refresher().refreshable {
                    await initialize()
                })
        }.task {
            await initialize()
        }
    }
}


//struct StudentUploadView_Previews: PreviewProvider {
//    static var previews: some View {
//        StudentUploadView()
//    }
//}

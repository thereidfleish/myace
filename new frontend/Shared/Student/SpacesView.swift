//
//  YourCoachesView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/22/21.
//

import SwiftUI

struct SpacesView: View {
    @EnvironmentObject private var nc: NetworkController
    
    // Passed-in properties
    //var currentUserAs: CurrentUserAs
    
    // Private properties
    @State private var showingNewBucketView = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var awaiting = false
    @State private var tabIndex: CourtshipType = .coach
    
    func initialize() async {
        do {
            awaiting = true
            try await nc.getCourtships(user_id: "me", type: tabIndex)
            awaiting = false
        } catch {
            print("Showing error: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
            awaiting = false
        }
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                VStack {
                    VStack(alignment: .leading) {
                        Text("\(Helper.computeWelcome()) \(Helper.firstName(name: nc.userData.shared.display_name))!")
                            .bucketNameStyle()
                            .foregroundColor(Color.green)
                            .onChange(of: tabIndex) { newValue in
                                Task {
                                    await initialize()
                                }
                            }
                        
                        Picker("", selection: $tabIndex) {
                            Text("Coaches").tag(CourtshipType.coach)
                            Text("Students").tag(CourtshipType.student)
                            Text("Friends").tag(CourtshipType.friend)
                        }.pickerStyle(.segmented)
                        
                        if nc.userData.courtships.isEmpty {
                            Text("Welcome!  To get started, use the search tab to search for some \(tabIndex == .coach ? "Coaches" : "Students").  Once they have accepted your courtship requests, they will appear here.")
                                .multilineTextAlignment(.center)
                                .padding(.top)
                        }
                        
                        
                        ScrollView {
                            if(awaiting) {
                                ProgressView()
                            }
                            else {
                                ForEach(nc.userData.courtships, id: \.self.id) { user in
                                    HStack {
                                        NavigationLink(destination: StudentUploadDetailView(otherUser: user, currentUserAs: {
                                            switch tabIndex {
                                            case .friend:
                                                return CourtshipType.friend
                                            case .coach:
                                                return CourtshipType.student
                                            case .student:
                                                return CourtshipType.coach
                                            default:
                                                return CourtshipType.undefined
                                            }
                                        }()).navigationTitle(user.display_name).navigationBarTitleDisplayMode(.inline))
                                        {
                                            VStack(alignment: .leading) {
                                                Text(user.display_name)
                                                    .bucketNameStyle()
                                                    .foregroundColor(Color.white)
                                                HStack {
                                                    Image(systemName: "person.fill")
                                                        .foregroundColor(Color.white)
                                                        .frame(width: 15)
                                                    Text("@\(user.username)")
                                                        .bucketTextExternalStyle()
                                                }
                                                
                                                //                        HStack {
                                                //                            Image(systemName: "text.bubble.fill")
                                                //                                .foregroundColor(.white)
                                                //                                .frame(width: 15)
                                                //                            if (/*studentInfo.numFeedback[i]*/ 0 == 0) {
                                                //                                Text(/*"\(studentInfo.numFeedback[i])*/ "New Feedback")
                                                //                                    .bucketTextExternalStyle()
                                                //                            }
                                                //                            else {
                                                //                                Text(/*"*\(studentInfo.numFeedback[i])*/ "New Feedback")
                                                //                                    .unreadBucketTextExternalStyle()
                                                //                            }
                                                //
                                                //                        }
                                                //
                                                //                        HStack {
                                                //                            Image(systemName: "clock.fill")
                                                //                                .foregroundColor(.white)
                                                //                                .frame(width: 15)
                                                //
                                                //                            Text("last modified here")
                                                //                                .bucketTextExternalStyle()
                                                //                        }
                                                
                                            }
                                            
                                            Spacer()
                                        }
                                        
                                        
                                    }.navigationLinkStyle()
                                }
                            }
                        }
                        
                        
                    }.sheet(isPresented: $showingNewBucketView) {
                        NewBucketView()
                        
                    }
                    
                }.padding(.horizontal)
                    .navigationBarTitle("Courtships", displayMode: .inline)
                    .navigationBarItems(trailing: Refresher().refreshable {
                        await initialize()
                    })
            }.navigationViewStyle(StackNavigationViewStyle())
                .task {
                    await initialize()
                }
            if showingError {
                Message(title: "Error", message: errorMessage, style: .error, isPresented: $showingError, view: nil)
            }
        }
    }
}


//struct StudentUploadView_Previews: PreviewProvider {
//    static var previews: some View {
//        StudentUploadView()
//    }
//}

//
//  YourCoachesView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/22/21.
//

import SwiftUI

struct FeedView: View {
    @EnvironmentObject private var nc: NetworkController
    
    // Passed-in properties
    //var currentUserAs: CurrentUserAs
    
    // Private properties
    @State private var showingNewBucketView = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var awaiting = false
    @State private var courtshipType: CourtshipType = .undefined
    @State private var pageNumber: Int = 1
    @State private var feedRes: FeedRes = FeedRes(feed: [])
    
    func initialize() async {
        do {
            awaiting = true
            
            /// hack to make feed view load lol
            try await nc.getBuckets(userID: "me")
            ///
            
            feedRes = try await nc.getFeed(type: courtshipType, page: pageNumber, per_page: 20)
            awaiting = false
            //return feedRes
        } catch {
            print("Showing error: \(error)")
            errorMessage = error.localizedDescription
            showingError = true
            awaiting = false
        }
        //return nil
    }
    
    var body: some View {
        ZStack {
            NavigationView {
                VStack {
                    VStack(alignment: .leading) {
                        Text("\(Helper.computeWelcome()) \(Helper.firstName(name: nc.userData.shared.display_name))!")
                            .bucketNameStyle()
                            .foregroundColor(Color.green)
                            .onChange(of: courtshipType) { newValue in
                                Task {
                                    await initialize()
                                }
                            }
                        
                        Menu {
                            Button("Everyone", action: {courtshipType = .undefined})
                            Button(action: {
                                courtshipType = .student
                            }, label: {
                                Label("Your Students", systemImage: "graduationcap.fill")
                            })
                            Button(action: {
                                courtshipType = .coach
                            }, label: {
                                Label("Your Coaches", systemImage: "rectangle.inset.filled.and.person.filled")
                            })
                            Button(action: {
                                courtshipType = .friend
                            }, label: {
                                Label("Your Friends", systemImage: "face.smiling.fill")
                            })
                        } label: {
                            HStack {
                                Text("Filter By: \(courtshipType == .undefined ? "Everyone" : "Your \(courtshipType == .coach ? "Coache" : courtshipType.rawValue.capitalized)s")").smallestSubsectionStyle()
                                    
                                
                                Image(systemName: "chevron.right")
                            }
                        }
                        
                        
                        ScrollView {
                            if(awaiting) {
                                ProgressView()
                            }
                            else {
                                if feedRes.feed.isEmpty {
                                    Text("Welcome!  To get started, use the search tab to search for some \(courtshipType == .undefined ? "Coaches, Students, or Friends" : "\(courtshipType == .coach ? "Coache" : courtshipType.rawValue.capitalized)s").  Once they have accepted your courtship requests and shared videos with you, they will appear here.")
                                        .multilineTextAlignment(.center)
                                        .padding(.top)
                                }

                                
                                ForEach(feedRes.feed, id: \.self.upload.id) { feedItem in
                                    VStack(alignment: .leading) {
//                                        HStack {
//                                            switch feedItem.user.courtship!.type {
//                                            case .friend:
//                                                Image(systemName: "face.smiling.fill").foregroundColor(.green)
//                                            case .coach:
//                                                Image(systemName: "rectangle.inset.filled.and.person.filled").foregroundColor(.green)
//                                            case .student:
//                                                Image(systemName: "graduationcap.fill").foregroundColor(.green)
//                                            default:
//                                                Image(systemName: "person.fill.questionmark").foregroundColor(.green)
//                                            }
//                                            
//                                            Text(feedItem.user.display_name).bucketTextInternalStyle()
//                                        }.padding(.bottom, -2)
//                                            .padding(.top, 5)
//                                        
//                                        RoundedRectangle(cornerRadius: 4)
//                                            .fill(Color.green)
//                                            .frame(height: 2)
                                        
                                        VideoView(upload: feedItem.upload, currentUserAs:
                                                    {
                                                        switch feedItem.user.courtship!.type {
                                                        case .friend:
                                                            return CourtshipType.friend
                                                        case .coach:
                                                            return CourtshipType.student
                                                        case .student:
                                                            return CourtshipType.coach
                                                        default:
                                                            return CourtshipType.undefined
                                                        }
                                        }(), otherUser: feedItem.user, initialize: {()}, showAsMe: false)
                                    }
                                }
                            }
                        }
                        
                        
                    }.sheet(isPresented: $showingNewBucketView) {
                        NewBucketView()
                        
                    }
                    
                }.padding(.horizontal)
                    .navigationBarTitle("Feed", displayMode: .inline)
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

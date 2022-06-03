//
//  SearchView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 1/19/22.
//

import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var nc: NetworkController
    @State private var searchText = ""
    @State private var awaiting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var searchedUsers: [SharedData] = []
    @State private var hasNext: Bool = false
    @State private var lastPageLoaded: Int = 1
    @State private var nextUsers: [SharedData] = []
    
    
    func search() async {
            do {
                awaiting = true
                print("searching")
                lastPageLoaded = 1
                let query = searchText.replacingOccurrences(of: " ", with: "")
                try await (searchedUsers, hasNext) = nc.searchUser(query: query, page: lastPageLoaded)
//                try await nextLoadedUsers = nc.searchUser(query: query, page: lastPageLoaded + 1)

                try await nc.getCourtships(user_id: "me", type: nil)
                try await nc.getCourtshipRequests(type: nil, dir: "in", users: nil)
                try await nc.getCourtshipRequests(type: nil, dir: "out", users: nil)
                print(searchedUsers)
                awaiting = false
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
                awaiting = false
            }
    }
    
    func loadMoreSearch() {
        Task {
            do {
                awaiting = true
                print("loading more results in")
                lastPageLoaded += 1
                (nextUsers, hasNext) = try await nc.searchUser(query: searchText.replacingOccurrences(of: " ", with: ""), page: lastPageLoaded)
                searchedUsers += nextUsers
                //print("next loaded---\(nextLoadedUsers) lastPageLoaded\(lastPageLoaded)")
                awaiting = false
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
                awaiting = false
            }
        }
    }
    
    var body: some View {
        NavigationView {
            
            VStack(alignment: .leading) {
                Text("Type a Username")
                    .bucketTextInternalStyle()
                    .padding(.top)
                
                TextField("Name", text: $searchText)
                    .autocapitalization(.none)
                    .textFieldStyle()
                    .onChange(of: searchText) { newValue in
                        Task {
                            await search()
                        }
                    }
                
                ScrollView {
                    ForEach(searchedUsers) { user in
                        
                        UserCardView(user: user)
                        
                    }
                    if(hasNext) {
                        Button(action: loadMoreSearch) {
                            Text("Load More...")
                                .bucketTextInternalStyle()
                                .padding()
                        }
                    }
                }
            }.navigationTitle("Search")
                .padding(.horizontal)
        }
    }
}

//struct SearchView_Previews: PreviewProvider {
//    static var previews: some View {
//        SearchView()
//    }
//}

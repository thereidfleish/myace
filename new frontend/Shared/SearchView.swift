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
    @State private var page: Int = 1
    
    func search() async {
            do {
                awaiting = true
                print("searching")
                page = 1
                try await searchedUsers = nc.searchUser(query: searchText.replacingOccurrences(of: " ", with: ""), page: page)
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
    
    func loadMoreSearch() async {
        do {
            awaiting = true
            print("loading more results in")
            page += 1
            try await searchedUsers = searchedUsers + nc.searchUser(query: searchText.replacingOccurrences(of: " ", with: ""), page: page)
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

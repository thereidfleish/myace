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
    
    func search() async {
            do {
                awaiting = true
                print("searching")
                try await searchedUsers = nc.searchUser(query: searchText.replacingOccurrences(of: " ", with: ""))
                try await nc.getCourtships(type: nil, users: nil)
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

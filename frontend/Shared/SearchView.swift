//
//  SearchView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 1/19/22.
//

import SwiftUI

struct SearchView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    
                }.padding(.horizontal)
                
                
            }.navigationTitle("thereidfleish")
                .navigationBarItems(leading: Button(action: {

                }, label: {
                    Text("Log Out")
                        .foregroundColor(Color.red)
                        .fontWeight(.bold)
                }))
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}

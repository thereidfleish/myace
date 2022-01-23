//
//  SettingsView.swift
//  AI Tennis Coach
//
//  Created by AndrewC on 1/23/22.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("General")
                        .bucketNameStyle()
                        .foregroundColor(Color.green)
                        .padding(.horizontal)
                        NavigationLink(destination: ProfileSettingsView(isNewUser: false)) {
                            HStack {
                                Text("Edit Profile Info")
                                    .bucketNameStyle()
                                    .foregroundColor(Color.white)
                                Spacer()
                                Image(systemName: "chevron.right.square.fill")
                                    .resizable()
                                    .scaledToFill()
                                    .foregroundColor(Color.white)
                                    .frame(width: 20, height: 20)
                            }
                            .navigationLinkStyle()
                        }
                }
            }
            .navigationTitle("Settings")
            .navigationBarItems(trailing:
                Button(action: {
                    self.mode.wrappedValue.dismiss()
                }, label: {
                    Text("Done")
                        .foregroundColor(.green)
                })

            )
        }

        

    }
}



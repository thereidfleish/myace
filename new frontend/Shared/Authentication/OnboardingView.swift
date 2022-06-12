//
//  OnboardingView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 6/11/22.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var nc: NetworkController
    @State private var showingNewBucketView = false
    @State var showProfileSettingsView: Bool
    
    var body: some View {
        VStack {
            if (showProfileSettingsView) {
                ProfileSettingsView(isNewUser: true, showProfileSettingsView: $showProfileSettingsView)
            }
            else if (nc.userData.shared.email_confirmed == false) {
                EmailNotConfirmedView()
            }
            else {
                Text("Welcome to MyAce")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.green)
                    .onAppear(perform: {
                        print(nc.userData.shared.email_confirmed)
                    })
                
                TabView {
                    Image("iPhone.001 copy")
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(10)
                    
                    Image("iPhone.002 copy")
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(10)
                    
                    Image("iPhone.003 copy")
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(10)
                    
                    Image("iPhone.004 copy")
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(10)
                    
                    Image("iPhone.005 copy")
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(10)
                    
                    VStack {
                        Text("Before getting started, you must create at least one folder. Folders are where you will store videos to share with your coaches, students, and friends.")
                            .padding(.top, 20)
                            .bucketTextInternalStyle()
                        Button(action: {
                            showingNewBucketView.toggle()
                        }, label: {
                            Text("Create New Folder")
                                .buttonStyle()
                        })
                        ForEach(nc.userData.buckets) { bucket in
                            VStack(alignment: .leading) {
                                Text(bucket.name)
                            }
                        }
                        
                        Button(action: {
                            nc.userData.showOnboarding = false
                            nc.userData.loggedIn = true
                            print(nc.userData.shared.email_confirmed)
                            print(nc.userData.loggedIn)
                        }, label: {
                            Text("Let's Go!")
                                .buttonStyle()
                        }).disabled(nc.userData.buckets.count == 0)
                            .opacity(nc.userData.buckets.count == 0 ? 0.5 : 1)
                    }
                    .padding(.horizontal)
                    .sheet(isPresented: $showingNewBucketView) {
                        NewBucketView()
                        
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
            }
            
            

        }
        
    }
}

//struct OnboardingView_Previews: PreviewProvider {
//    static var previews: some View {
//        OnboardingView()
//    }
//}

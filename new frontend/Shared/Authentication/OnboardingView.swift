//
//  OnboardingView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 6/11/22.
//

import SwiftUI

struct OnboardingView: View {
    var body: some View {
        VStack {
            Text("Welcome to MyAce")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.green)
            
            TabView {
                        Image("iPhone.001")
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(10)                
                
                        Text("Second")
                        Text("Third")
                        Text("Fourth")
                    }
                    .tabViewStyle(.page)
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}

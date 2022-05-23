//
//  Refresher.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 5/23/22.
//

import SwiftUI

struct Refresher: View {
    @Environment(\.refresh) private var refresh
    @State private var isLoading = false
//    var animation: Animation {
//        Animation.linear(duration: 2.0)
//        .repeatForever(autoreverses: false)
//    }
    
    var body: some View {
        VStack {
            if let refresh = refresh {
                if isLoading {
                    ProgressView()
                } else {
                    Button(action: {
                        isLoading = true
                        Task {
                            await refresh()
                            isLoading = false
                        }
                    }, label: {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .foregroundColor(Color.green)
//                            .rotationEffect(Angle.degrees(isLoading ? 360 : 0))
//                            .animation(animation)
                    })
                }
                
            }
            
        }
    }
}

struct Refresher_Previews: PreviewProvider {
    static var previews: some View {
        Refresher()
    }
}

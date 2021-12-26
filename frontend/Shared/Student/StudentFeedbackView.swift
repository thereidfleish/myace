//
//  StudentFeedbackView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/22/21.
//

import SwiftUI

struct StudentFeedbackView: View {
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    var text: String
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(text)
            }.navigationTitle("Feedback")
                .navigationBarItems(trailing: Button("Close") {
                    self.mode.wrappedValue.dismiss()
                })
        }
        
    }
}

//struct StudentFeedbackView_Previews: PreviewProvider {
//    static var previews: some View {
//        StudentFeedbackView()
//    }
//}

//
//  StudentFeedbackView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/22/21.
//

import SwiftUI

struct StudentFeedbackView: View {
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    @State var text: String
    var student: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    if (student) {
                        Text(text)
                            .multilineTextAlignment(.leading)
                    }
                    else {
                        
                        Text("Unsaved changes")
                            .font(.footnote)
                            .foregroundColor(Color.red)
                        
                        TextEditor(text: $text)
                            .padding(1)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                            .frame(minHeight: UIScreen.screenHeight - 200)
                        
                    }
                    
                }.padding(.horizontal)
            }.navigationTitle("Feedback")
                .navigationBarItems(trailing: student ? Button("Close") {
                    self.mode.wrappedValue.dismiss()
                } : Button("Save and Close") {
                    print("saving...")
                    self.mode.wrappedValue.dismiss()
                })
        }
        
    }
}

extension UIScreen{
    static let screenWidth = UIScreen.main.bounds.size.width
    static let screenHeight = UIScreen.main.bounds.size.height
    static let screenSize = UIScreen.main.bounds.size
}

//struct StudentFeedbackView_Previews: PreviewProvider {
//    static var previews: some View {
//        StudentFeedbackView()
//    }
//}

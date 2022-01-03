//
//  NewBucketView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/27/21.
//

import SwiftUI

struct NewBucketView: View {
    @EnvironmentObject private var nc: NetworkController
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    private var defaultStrokes = ["Backhand Groundstroke", "Forehand Groundstroke", "Backhand Volley", "Forehand Volley", "Serve"]
    @State private var awaiting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var name: String = ""
    
    func add() {
        Task {
            do {
                awaiting = true
                try await nc.addBucket(userID: "\(nc.userData.shared.id)", name: name)
                print("DONE!")
            } catch {
                print(error)
                errorMessage = error.localizedDescription
                showingError = true
            }
            awaiting = false
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Choose from a default stroke or add a custom stroke")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Menu {
                        ForEach(defaultStrokes, id: \.self) { stroke in
                            Button(stroke) {
                                name = stroke
                            }
                        }
                    } label: {
                        Text("Choose from a default stroke")
                            .padding(.vertical, 15)
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                            .foregroundColor(.white)
                    }
                    
                    Text("Name")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .padding(.top)
                    
                    HStack {
                        TextField("Name", text: $name)
                            .autocapitalization(.none)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(defaultStrokes.contains(name))
                        
                        Button("Clear") {
                            name = ""
                        }
                    }
                    
                    
                }.padding(.horizontal)
            }.navigationTitle("New Stroke")
                .navigationBarItems(leading: Button(action: {
                    self.mode.wrappedValue.dismiss()
                }, label: {
                    Text("Cancel")
                        .foregroundColor(Color.green)
                        .fontWeight(.bold)
                }),trailing: Button(action: {
                    add()
                    self.mode.wrappedValue.dismiss()
                }, label: {
                    if (awaiting) {
                        ProgressView()
                    } else if (showingError) {
                        Text(UserData.computeErrorMessage(errorMessage: errorMessage)).padding()
                    } else {
                        Text("Save and Close")
                            .foregroundColor(Color.green)
                            .fontWeight(.bold)
                    }
                }))
        }
    }
}

//struct NewBucketView_Previews: PreviewProvider {
//    static var previews: some View {
//        NewBucketView()
//    }
//}

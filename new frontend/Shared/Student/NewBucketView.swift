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
    @State private var name: String = ""
    
    func add() async {
        do {
            awaiting = true
            try await nc.createBucket(name: name)
            self.mode.wrappedValue.dismiss()
        } catch {
            print(error)
            showingError = true
        }
        awaiting = false
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading) {
                    Text("Choose from a default stroke or add a custom stroke")
                        .bucketTextInternalStyle()
                    
                    Menu {
                        ForEach(defaultStrokes, id: \.self) { stroke in
                            Button(stroke) {
                                name = stroke
                            }
                        }
                    } label: {
                        Text("Choose from a default stroke")
                            .buttonStyle()
                    }
                    
                    Text("Name")
                        .bucketTextInternalStyle()
                        .padding(.top)
                    
                    HStack {
                        TextField("Name", text: $name)
                            .autocapitalization(.none)
                            .textFieldStyle()
                            .disabled(defaultStrokes.contains(name))
                        
                        Button("Clear") {
                            name = ""
                        }.disabled(name == "")
                    }
                    
                    if (showingError) {
                        Text(nc.errorMessage)
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
                    Task {
                        await add()
                    }
                }, label: {
                    if (awaiting) {
                        ProgressView()
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

//
//  Info.swift
//  QT
//
//  Created by Reid on 2/1/21.
//

import SwiftUI

struct TeamMember: Identifiable {
    var imageName: String
    var name: String
    var position: String
    var id: Int
}

struct Info: View {
    @Environment(\.presentationMode) var mode: Binding<PresentationMode>
    @State private var tapCount = 0
    @State private var teamMembers : [TeamMember] = [
        TeamMember(imageName: "chris", name: "Chris Price", position: "CEO", id: 0),
        TeamMember(imageName: "adler", name: "Adler Weber", position: "Backend", id: 1),
        TeamMember(imageName: "reid", name: "Reid Fleishman", position: "iOS", id: 2),
        TeamMember(imageName: "andrew", name: "Andrew Chen", position: "iOS", id: 3),
    ]
    private var tapCountThreshold = 100
    var body: some View {
        NavigationView {
            
            ZStack {
                //Color.LightPurple.edgesIgnoringSafeArea(.all)
                
                ScrollView(.vertical) {
                    VStack(alignment: .center) {
                        Image("icon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250)
                            .cornerRadius(50)
                            .shadow(radius: 5)
                            .padding(.top)
                        
                        Text("MyAce")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Text("Version 1.0.0 (1)")
                            .foregroundColor(.green)
                    }
                    
                    VStack(alignment: .leading) {
                        
                        Text("Meet the team")
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .padding(.top, 20.0)
                        ForEach(teamMembers, id: \.self.id) { member in
                            VStack {
                                Image(tapCount >= tapCountThreshold ? "icon" : member.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(Color.white)
                                    .frame(width: 150, height: 150)
                                    .clipShape(/*@START_MENU_TOKEN@*/Circle()/*@END_MENU_TOKEN@*/)
                                    .padding(.trailing, 10.0)
                                
                                Text(member.name)
                                    .font(.title2)
                                    .fontWeight(.heavy)
                                    .foregroundColor(Color.white)
                                Text(tapCount >= tapCountThreshold ? "Tennis Ball" : member.position)
                                    .font(.title3)
                                    .foregroundColor(Color.white)
                                    .frame(maxWidth: .infinity)
                            }
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                        }
                        Button(action: {
                            tapCount += 1;
                        }) {
                            Text("© 2022 MyAce")
                                .foregroundColor(.green)
                        }
                    }.padding(.horizontal)

                }
            }.navigationBarTitle("About This App", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") {
                self.mode.wrappedValue.dismiss()
            })
            
        }
        
    }
}

struct Info_Previews: PreviewProvider {
    static var previews: some View {
        Info()
    }
}

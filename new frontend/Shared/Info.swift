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
    private var teamMembers : [TeamMember] = [
        TeamMember(imageName: "chris", name: "Chris Price", position: "CEO", id: 0),
        TeamMember(imageName: "adler", name: "Adler Weber", position: "Backend", id: 1),
        TeamMember(imageName: "reid", name: "Reid Fleishman", position: "iOS", id: 2),
        TeamMember(imageName: "andrew", name: "Ansdrew Chen", position: "iOS", id: 3),
    ]
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
                                Image(member.imageName)
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
                                Text(member.position)
                                    .font(.title3)
                                    .foregroundColor(Color.white)
                                    .frame(maxWidth: .infinity)
                            }
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                        }
                        
                        
                        
                        
                        Text("Tools")
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                            .padding(.top, 20.0)
                        
                        Text("SwiftUI and Xcode\nFirebase Cloud Firestore\nFirebase Cloud Messaging")
                            .foregroundColor(.purple)
                        
                        Text("Questions, Comments, or Suggestions???")
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                            .padding(.top, 20.0)
                        
                        Button("reidfleishman5@gmail.com") {
                            UIApplication.shared.open(URL(string: "mailto:reidfleishman5@gmail.com")!)
                        }
                        .foregroundColor(.purple)
                        
                    }.padding(.horizontal)
                    
                    VStack(alignment: .leading) {
                        
                        Text("Changelog")
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                            .padding(.top, 20.0)
                        
                        Text("Version 1.1.2 (1) (10/8/21)\n- Fixed a few UI issues from iOS 15, including the inability of tutors to create new sessions.\n\nVersion 1.1.1 (1) (3/31/21)\n- Minor bug fixes and UI changes\n\nVersion 1.1 (3) (2/12/21)\n- Tutors can now create new sessions in the app\n- Critical crash and bug fixes\n- The app now supports Dark Mode!\n- Other minor UI changes")
                            .foregroundColor(.purple)
                        
                        Text("Disclaimers")
                            .fontWeight(.bold)
                            .foregroundColor(.purple)
                            .padding(.top, 20.0)
                        
                        Text("© 2022 MyAce")
                            .foregroundColor(.purple)
                        
                        Button(action: {
                            tapCount += 1;
                        }) {
                        Text("\nSpecial thanks to Eden Katz for beta testing the app and helping add the tutors <3")
                            .foregroundColor(.purple)
                        }
                        
                        if tapCount >= 118 {
                            Text("\nI love you soooooooooooooooooo much ❤️")
                                .foregroundColor(.purple)
                        }
                    }
                    .padding(.horizontal)
                    
                    Text("Happy Tutoring :)\n~The QT Team")
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                        .multilineTextAlignment(.center)
                        .padding(.top, 20.0)
                    
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

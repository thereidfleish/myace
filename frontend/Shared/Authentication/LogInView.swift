//
//  LogInView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/27/21.
//

import SwiftUI
import GoogleSignIn

//class GoogleStuff: UIViewController, ObservableObject {
//    static var shared = GoogleStuff()
//    var googleSignIn = GIDSignIn.sharedInstance
//    var googleId = ""
//    var googleIdToken = ""
//    var googleFirstName = ""
//    var googleLastName = ""
//    var googleEmail = ""
//    var googleProfileURL = ""
//
//
//
//    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
//
//        guard user != nil else {
//            print("Uh oh. The user cancelled the Google login.")
//            return
//        }
//
//        print("TOKEN => \(user.authentication.idToken!)")
//
//
//    }
//
//    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
//
//        guard user != nil else {
//            print("Uh oh. The user cancelled the Google login.")
//            return
//        }
//
//        print("TOKEN => \(user.authentication.idToken!)")
//
//    }
//}

struct GoogleAuthRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> some UIViewController {
        //let vc = UIViewController()
        let vc = GoogleAuth.instance
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {

    }
}

class GoogleAuth: UIViewController {
    static var instance = GoogleAuth() 
}

struct LogInView: View {
    @EnvironmentObject private var nc: NetworkController
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack {
            Text("AI Tennis Coach")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(Color.green)
            
            Button(action: {
                Task {
                    do {
                        nc.awaiting = true
                        try await nc.authenticate(token: "test", type: 0)
                    } catch {
                        print(error)
                        errorMessage = error.localizedDescription
                        showingError = true
                    }
                    nc.awaiting = false
                    print(nc.userData.shared)
                }
                
                
            }, label: {
                if (nc.awaiting) {
                    ProgressView()
                } else if (showingError) {
                    Text("Error: \(errorMessage).  \(errorMessage.contains("0") ? "JSON Encode Error" : "JSON Decode Error").  Please check your internet connection, or try again later.").padding()
                } else {
                    Text("Sign In With Google")
                        .padding(.vertical, 15)
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }
            })
            
            Button(action: {
                nc.userData.shared.type = 0
            }, label: {
                Text("fake a student view for now lol")
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
                    .foregroundColor(.white)
            })
            
            Button(action: {
                nc.userData.shared.type = 1
            }, label: {
                Text("fake a coach view for now lol")
                    .padding(.vertical, 15)
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
                    .foregroundColor(.white)
            })
            
            
        }.padding(.horizontal)
    }
}

struct LogInView_Previews: PreviewProvider {
    static var previews: some View {
        LogInView()
    }
}

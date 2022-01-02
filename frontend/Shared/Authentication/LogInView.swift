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
    private let signInConfig = GIDConfiguration.init(clientID: "353843950130-ltob99bnq2pukci7m1qckaotg74f07m9.apps.googleusercontent.com")
    private let host = "https://tennistrainerapi.2h4barifgg1uc.us-east-2.cs.amazonlightsail.com"
    var googleAuth = GoogleAuth.instance
    //@EnvironmentObject var delegate: AppDelegate
    
    var body: some View {
        ZStack {
            GoogleAuthRepresentable()
            VStack {
                Text("AI Tennis Coach")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.green)
                
                Button(action: {
    //                Task {
    //                    do {
    //                        nc.awaiting = true
    //                        try await nc.authenticate(token: "test", type: 0)
    //                    } catch {
    //                        print(error)
    //                        errorMessage = error.localizedDescription
    //                        showingError = true
    //                    }
    //                    nc.awaiting = false
    //                    print(nc.userData.shared)
    //                }
                    
                    signIn(withVC: googleAuth)
                    
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
    
    func signIn(withVC vc: UIViewController) {
      GIDSignIn.sharedInstance.signIn(with: signInConfig, presenting: vc) { user, error in
          guard error == nil else {
              print("hello")
              return
              
          }
          guard let user = user else { return }
          
          let emailAddress = user.profile?.email

          let fullName = user.profile?.name
          let givenName = user.profile?.givenName
          let familyName = user.profile?.familyName
          let profilePicUrl = user.profile?.imageURL(withDimension: 320)

          if let uUserID = user.userID {
              
          } else {
              print("Failed unwrapping of UserID")
          }
     
          user.authentication.do { authentication, error in
            guard error == nil else {

                return

            }
            guard let authentication = authentication else { return }
              let idToken = authentication.idToken
              if let uIdToken = idToken {
                  self.tokenSignIn(idToken: uIdToken)
              } else {
                  print("Authentication Failed")
              }

          }
          
      }
    }
    func tokenSignIn(idToken: String) {
        let json: [String: Any] = ["token": idToken, "type": 0]
        
//        guard let authData = try? JSONEncoder().encode(["token": idToken, "type": 0]) else {
//            return
//        }
        guard let authData = try? JSONSerialization.data(withJSONObject: json) else {
            return
        }
        let url = URL(string: "\(host)/api/user/authenticate/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let task = URLSession.shared.uploadTask(with: request, from: authData) { data, response, error in
            print(response)
        }
        task.resume()
    }
   
    
}

struct LogInView_Previews: PreviewProvider {
    static var previews: some View {
        LogInView()
    }
}

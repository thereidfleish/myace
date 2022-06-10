//
//  LogInView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/27/21.
//

import SwiftUI
import GoogleSignIn
import AuthenticationServices

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
    private let signInConfig = GIDConfiguration.init(clientID: "530607482320-irblcmsai0p4dn8ocq9bmjv31jo1j3se.apps.googleusercontent.com")
    private let host = "https://api.myace.ai"
    var googleAuth = GoogleAuth.instance
    //@EnvironmentObject var delegate: AppDelegate
    @State private var awaiting = true
    
    @State private var prevSignIn: [Any] = UserDefaults.standard.array(forKey: "appletoken") ?? [signedInWith.none, Data()]
    
    func signIn(withVC vc: UIViewController) {
        GIDSignIn.sharedInstance.signIn(with: signInConfig, presenting: vc) { user, error in
            guard error == nil else {
                print(error.debugDescription)
                awaiting = false
                return
                
            }
            guard let user = user else { return }
            
            //          let emailAddress = user.profile?.email
            //
            //          let fullName = user.profile?.name
            //          let givenName = user.profile?.givenName
            //          let familyName = user.profile?.familyName
            //          let profilePicUrl = user.profile?.imageURL(withDimension: 320)
            
            if let uUserID = user.userID {
                print(uUserID)
            } else {
                print("Failed unwrapping of UserID")
            }
            
            authenticate(user: user)
            
        }
    }
    
    func authenticate(user: GIDGoogleUser) {
        nc.userData.profilePic = user.profile?.imageURL(withDimension: 320)
        
        user.authentication.do { authentication, error in
            guard error == nil else {
                
                return
                
            }
            guard let authentication = authentication else { return }
            let idToken = authentication.idToken
            if let uIdToken = idToken {
                Task {
                    try await nc.login(method: "google", email: nil, password: nil, token: uIdToken)
                }
            } else {
                print("Authentication Failed")
            }
            
        }
    }
    
    func checkPreviousSignIn() {
        print("checking previous sign in...")
        
        switch prevSignIn[0] as! signedInWith {
        case .none:
            awaiting = false
        case .google:
            GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
                if let error = error {
                    self.errorMessage = "error: \(error.localizedDescription)"
                }
                
                if let user = user {
                    print("found a previous sign in!")
                    authenticate(user: user)
                } else {
                    print("did not find a previous sign in :(")
                    awaiting = false
                }
            }
        case .apple:
            Task {
                try await nc.login(method: "apple", email: nil, password: nil, token: String(decoding: prevSignIn[1] as! Data, as: UTF8.self))
            }
        case .email:
            Task {
                //try await nc.login(method: "password", email: email, password: password, token: nil)
            }
        }
        
        
        //awaiting = false
    }

    var body: some View {
        NavigationView {
            ZStack {
                GoogleAuthRepresentable()
                VStack {
                    Text("Welcome to MyAce")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(Color.green)
                        .padding(.top, 20)
                        .onAppear(perform: {
                            checkPreviousSignIn()
                        })
                    
                    Spacer()
                    
                    if (awaiting) {
                        ProgressView().padding()
                    } else if (showingError) {
                        Text(nc.errorMessage).padding()
                    } else {
                        Button(action: {
                            awaiting = true
                            signIn(withVC: googleAuth)
                        }, label: {
                            Text("Sign in with Google")
                                .buttonStyle()
                        })
                        
                        SignInWithAppleButton(.signIn) { request in
                            request.requestedScopes = [.email, .fullName]
                        } onCompletion: { result in
                            switch result {
                                case .success(let authResults):
                                switch authResults.credential {
                                case let credential as ASAuthorizationAppleIDCredential:
                                    let userID = credential.user
                                    let token1 = credential.authorizationCode
                                    let token2 = credential.identityToken
                                    
                                    let email = credential.email
                                    let name = credential.fullName
                                    
                                    print(userID)
                                    print(token1)
                                    print(token2)
                                    print(email)
                                    print(name)
                                    
                                    //print("calling TokenSignIn with token1...")
                                    //self.tokenSignIn(idToken: String(decoding: token1!, as: UTF8.self), method: "apple")
                                    print("calling TokenSignIn with token2...")
                                    if let token2 = token2 {
                                        Task {
                                            try await nc.login(method: "apple", email: nil, password: nil, token: String(decoding: token2, as: UTF8.self))
                                            UserDefaults.standard.set(token2, forKey: "appletoken")
                                        }
                                    }
                                    
                                    print("finished calling TokenSignIns")
                                default: break
                                }
                                case .failure(let error):
                                    print("Authorization failed: \(error.localizedDescription)")
                            }
                        }
                        .frame(height: 52.5)
                        .cornerRadius(10)

                        Text("Or")
                            .padding(.vertical)
                            .bucketTextInternalStyle()
                        
                        NavigationLink(destination: LogInEmailView()) {
                            Text("Sign in with Email")
                                .buttonStyle()
                        }
                        

                        
                    }
                    
                    Spacer()
                    
                    
                }.padding(.horizontal)
                
            }
        }
    }
    

    
    
}

//struct LogInView_Previews: PreviewProvider {
//    static var previews: some View {
//        LogInView()
//    }
//}

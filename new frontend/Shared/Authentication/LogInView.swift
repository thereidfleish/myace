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
    @Environment(\.colorScheme) var colorScheme
    @State private var showingError = false
    @State private var errorMessage = ""
    private let signInConfig = GIDConfiguration.init(clientID: "530607482320-irblcmsai0p4dn8ocq9bmjv31jo1j3se.apps.googleusercontent.com")
    private let host = "https://api.myace.ai"
    var googleAuth = GoogleAuth.instance
    //@EnvironmentObject var delegate: AppDelegate
    @State private var awaiting = true
    @State private var showAboutPage = false
    
    func checkPreviousSignIn() {
        print("checking previous sign in...")
        
        Task {
            do {
                nc.userData.shared = try await nc.getIndividualUser(userID: "me")
                nc.userData.loggedIn = true
            }
            catch {
                awaiting = false
            }
            
        }
    }
        
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
                    do {
                        try await nc.login(method: "google", email: nil, password: nil, token: uIdToken)
                        awaiting = false
                    }
                    catch {
                        print("Showing error: \(error)")
                        errorMessage = error.localizedDescription
                        showingError = true
                        awaiting = false
                    }
                }
            } else {
                print("Authentication Failed")
            }
            
        }
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
                            HStack {
                                Image("google")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 20, height: 20)
                                Text("Sign in with Google")
                                    
                            }.buttonStyle()
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

                                    print("calling TokenSignIn with token2...")
                                    if let token2 = token2 {
                                        awaiting = true
                                        Task {
                                            do {
                                                try await nc.login(method: "apple", email: nil, password: nil, token: String(decoding: token2, as: UTF8.self))
                                                awaiting = false
                                            } catch {
                                                print("Showing error: \(error)")
                                                errorMessage = error.localizedDescription
                                                showingError = true
                                                awaiting = false
                                            }
                                            
                                        }
                                        
                                    }
                                    
                                    print("finished calling TokenSignIns")
                                default: break
                                }
                                case .failure(let error):
                                    print("Showing error: \(error)")
                                    errorMessage = error.localizedDescription
                                    showingError = true
                            }
                        }
                        .frame(height: 52.5)
                        .cornerRadius(10)
                        .invertColorStyle(enabled: colorScheme == .dark)

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
                
                if showingError {
                    Message(title: "Error", message: errorMessage, style: .error, isPresented: $showingError, view: nil)
                }
            }
            .sheet(isPresented: $showAboutPage) {
                Info()
            }
            .navigationBarItems(trailing:
                                    Button(action: {
                showAboutPage.toggle()
            }, label: {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Color.green)
            }))
        }.navigationViewStyle(StackNavigationViewStyle())
    }
    

    
    
}

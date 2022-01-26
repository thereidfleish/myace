//
//  LogInView.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/27/21.
//

import SwiftUI
import GoogleSignIn

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
    @AppStorage("type") private var typeSelection = -1
    
    var body: some View {
        ZStack {
            GoogleAuthRepresentable()
            VStack {
                Text("AI Tennis Coach")
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
                    Text(UserData.computeErrorMessage(errorMessage: errorMessage)).padding()
                } else {
                    Text("Are you a player or a coach?")
                        .bucketTextInternalStyle()
                    
                    Picker("Are you a player or a coach?", selection: $typeSelection) {
                        Text("Player").tag(0)
                        Text("Coach").tag(1)
                    } .pickerStyle(.segmented)
                    
                    
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
                        awaiting = true
                        signIn(withVC: googleAuth)
                    }, label: {
                        Text("Sign In With Google")
                            .buttonStyle()
                            .opacity(typeSelection == -1 ? 0.75 : 1)
                    }).disabled(typeSelection == -1)
                }
                
                Spacer()
                
                //                Button(action: {
                //                    nc.userData.shared.type = 0
                //                }, label: {
                //                    Text("fake a student view for now lol")
                //                        .padding(.vertical, 15)
                //                        .frame(maxWidth: .infinity)
                //                        .background(Color.green)
                //                        .cornerRadius(10)
                //                        .foregroundColor(.white)
                //                })
                //
                //                Button(action: {
                //                    nc.userData.shared.type = 1
                //                }, label: {
                //                    Text("fake a coach view for now lol")
                //                        .padding(.vertical, 15)
                //                        .frame(maxWidth: .infinity)
                //                        .background(Color.green)
                //                        .cornerRadius(10)
                //                        .foregroundColor(.white)
                //                })
                
                
            }.padding(.horizontal)
            
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
                self.tokenSignIn(idToken: uIdToken)
            } else {
                print("Authentication Failed")
            }
            
        }
    }
    
    func tokenSignIn(idToken: String) {
        let json: [String: Any] = ["token": idToken, "type": typeSelection]
        print(idToken)
        
        //        guard let authData = try? JSONEncoder().encode(["token": idToken, "type": 0]) else {
        //            return
        //        }
        guard let authData = try? JSONSerialization.data(withJSONObject: json) else {
            return
        }
        let url = URL(string: "\(host)/login/")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.uploadTask(with: request, from: authData) { data, response, error in
            print(response.debugDescription)
            
            print(data!.prettyPrintedJSONString)
            print("NO \(error.debugDescription)")
            
            
            guard let data = data else {
                print("URLSession dataTask error:", error ?? "nil")
                return
            }
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            do {
                let decodedResponse = try decoder.decode(SharedData.self, from: data)
                nc.userData.shared = decodedResponse
                
                // Handle the new user
                if (response.debugDescription.contains("Status Code: 201")) {
                    nc.newUser = true
                }
                
            } catch {
                print("Error")
                awaiting = false
            }
        }
        task.resume()
    }
    
    func checkPreviousSignIn() {
        GIDSignIn.sharedInstance.restorePreviousSignIn { user, error in
            if let error = error {
                self.errorMessage = "error: \(error.localizedDescription)"
            }
            
            if let user = user {
                authenticate(user: user)
            } else {
                awaiting = false
            }
            
        }
        
        //awaiting = false
    }
    
    
}

struct LogInView_Previews: PreviewProvider {
    static var previews: some View {
        LogInView()
    }
}

//
//  NetworkController.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/29/21.
//

import Foundation

class NetworkController: ObservableObject {
    @Published var userData: UserData = UserData(shared: SharedData(id: "", display_name: "", email: "", type: -1), uploads: [])
    
    // POST
    func authenticate(token: String, type: Int) async {
        let req: AuthReq = AuthReq(token: token, type: type)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            print("Failed to encode")
            return
        }
        
        let url = URL(string: "https://reqres.in/api/cupcakes")!
        
        
        //        let body = """
        //            {
        //                "token": "\(token)"
        //            }
        //            """
        //        let finalBody = body.data(using: .utf8)
        //        print(finalBody.)
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        do {
            let (data, _) = try await URLSession.shared.upload(for: request, from: encoded)
            let decodedResponse = try JSONDecoder().decode(SharedData.self, from: data)
            print("UID: \(decodedResponse.id)")
        } catch {
            print("Checkout failed.")
        }
        
        //        let finalRequest = NetworkRequest(url: request)
        //        finalRequest.execute { [weak self] (data) in
        //            if let data = data {
        //                self?.authenticationDecode(data)
        //                print("done")
        //            } else {
        //                print("error in \(url.absoluteString)")
        //            }
        //        }
    }
    
    // GET
    func getAllUploads(uid: String) async {
        let url = URL(string: "/api/user/\(uid)/uploads/")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let decodedResponse = try? JSONDecoder().decode([Upload].self, from: data) {
                userData.uploads = decodedResponse
            }
        } catch {
            print("Invalid data")
        }
    }
    
    // GET
    func getUpload(uid: String, uploadID: String) async -> Upload {
        let url = URL(string: "/api/user/\(uid)/upload/\(uploadID)")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let decodedResponse = try? JSONDecoder().decode(Upload.self, from: data) {
                return decodedResponse
            }
        } catch {
            print("Invalid data")
        }
        return Upload(uploadID: -1, dateCreated: "?", displayTitle: "?", streamReady: false, comments: [])
    }
    
    // POST - NEED TO FIX THE VIDEORES STRUCT CUZ IT HAS "-" IN SPEC INSTEAD OF "_"
    func upload(filename: String, display_title: String, uid: String) async {
        let req: VideoReq = VideoReq(filename: filename, display_title: display_title)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            print("Failed to encode")
            return
        }
        
        let url = URL(string: "/api/user/\(uid)/upload/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        do {
            let (data, _) = try await URLSession.shared.upload(for: request, from: encoded)
            //let decodedResponse = try JSONDecoder().decode(VideoRes.self, from: data)
            //print("Token: \(decodedResponse.token)")
        } catch {
            print("Checkout failed.")
        }
    }
    
    // POST - HOW THE HELL DO YOU DO A POST REQUEST WITHOUT SENDING ANYTHING???
    func convert(uid: String, uploadID: String) async {
        //        let req: VideoReq = VideoReq(filename: filename, display_title: display_title)
        //
        //        guard let encoded = try? JSONEncoder().encode(req) else {
        //            print("Failed to encode")
        //            return
        //        }
        //
        //        let url = URL(string: "https://reqres.in/api/cupcakes")!
        //
        //        var request = URLRequest(url: url)
        //        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        //        request.httpMethod = "POST"
        //
        //        do {
        //            let (data, _) = try await URLSession.shared.upload(for: request, from: encoded)
        //            let decodedResponse = try JSONDecoder().decode(VideoRes.self, from: data)
        //            //print("Token: \(decodedResponse.token)")
        //        } catch {
        //            print("Checkout failed.")
        //        }
    }
    
    // POST
    func addComment(uploadID: String, authorID: String, text: String) async {
        let req: CommentReq = CommentReq(author_id: authorID, text: text)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            print("Failed to encode")
            return
        }
        
        let url = URL(string: "/api/upload/\(uploadID)/comment/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        do {
            let (data, _) = try await URLSession.shared.upload(for: request, from: encoded)
            let decodedResponse = try JSONDecoder().decode(Comment.self, from: data)
            //print("Token: \(decodedResponse.token)")
        } catch {
            print("Checkout failed.")
        }
    }
    
    
}

//private extension NetworkController {
//    func authenticationDecode(_ JSONdata: Data) {
//        let decoder = JSONDecoder()
//        decoder.dateDecodingStrategy = .iso8601
//        let response: SharedData = (try? decoder.decode(SharedData.self, from: JSONdata)) ?? SharedData(userType: -1, uid: "", display_name: "", email: "")
//        userData.shared = response
//    }
//}

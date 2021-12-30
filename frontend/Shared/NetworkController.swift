//
//  NetworkController.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/29/21.
//

import Foundation

class NetworkController: ObservableObject {
    @Published var userData: UserData = UserData(shared: SharedData(id: "", display_name: "", email: "", type: -1), uploads: [], buckets: [], bucketContents: [])
    @Published var awaiting = false
    private let host = "https://tennis-trainer.herokuapp.com"
    
    // POST
    func authenticate(token: String, type: Int) async throws {
        awaiting = true
        let req: AuthReq = AuthReq(token: token, type: type)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            
            throw NetworkError.failedEncode
        }
        
        let url = URL(string: "\(host)/api/user/authenticate/")!
        
        
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
            userData.shared = decodedResponse
        } catch {
            
            throw NetworkError.failedDecode
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
        awaiting = false
    }
    
    // GET
    func getAllUploads(uid: String) async throws {
        let url = URL(string: "\(host)/api/user/\(uid)/uploads/")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let decodedResponse = try? JSONDecoder().decode([Upload].self, from: data) {
                userData.uploads = decodedResponse
            }
        } catch {
            
            throw NetworkError.failedDecode
        }
    }
    
    // GET
    func getUpload(uid: String, uploadID: String) async throws -> Upload {
        let url = URL(string: "\(host)/api/user/\(uid)/upload/\(uploadID)/")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let decodedResponse = try? JSONDecoder().decode(Upload.self, from: data) {
                return decodedResponse
            }
        } catch {
            
            throw NetworkError.failedDecode
        }
        throw NetworkError.noReturn
        //        return Upload(id: -1, created: "?", display_title: "?", stream_ready: false, bucket_id: -1, comments: [], url: "?")
    }
    
    // POST - NEED TO FIX THE VIDEORES STRUCT CUZ IT HAS "-" IN SPEC INSTEAD OF "_"
    func upload(filename: String, display_title: String, bucket_id: Int, uid: String) async throws -> VideoRes {
        let req: VideoReq = VideoReq(filename: filename, display_title: display_title, bucket_id: bucket_id)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            
            throw NetworkError.failedEncode
            //            return VideoRes(id: "?", url: "?", fields: Field(key: "", x_amz_algorithm: "", x_amz_credential: "", x_amz_date: "", policy: "", x_amz_signature: ""))
        }
        
        let url = URL(string: "\(host)/api/user/\(uid)/upload/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        do {
            let (data, _) = try await URLSession.shared.upload(for: request, from: encoded)
            let decodedResponse = try JSONDecoder().decode(VideoRes.self, from: data)
            return decodedResponse
        } catch {
            
            throw NetworkError.failedDecode
        }
        throw NetworkError.noReturn
        //        return VideoRes(id: "?", url: "?", fields: Field(key: "", x_amz_algorithm: "", x_amz_credential: "", x_amz_date: "", policy: "", x_amz_signature: ""))
    }
    
    // POST - HOW THE HELL DO YOU DO A POST REQUEST WITHOUT SENDING ANYTHING???
    func convert(uid: String, uploadID: String) async throws {
        //        let req: VideoReq = VideoReq(filename: filename, display_title: display_title)
        //
        //        guard let encoded = try? JSONEncoder().encode(req) else {
        //
        //            throw NetworkError.failedEncode
        //        }
        //
        //        let url = URL(string: "\(host)/api/user/\(uid)/upload/\(uploadID)/convert/")!
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
        //
        //            throw NetworkError.failedDecode
        //        }
    }
    
    // POST
    func addComment(uploadID: String, authorID: String, text: String) async throws {
        let req: CommentReq = CommentReq(author_id: authorID, text: text)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            
            throw NetworkError.failedEncode
        }
        
        let url = URL(string: "\(host)/api/upload/\(uploadID)/comment/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        do {
            let (data, _) = try await URLSession.shared.upload(for: request, from: encoded)
            let decodedResponse = try JSONDecoder().decode(Comment.self, from: data)
            for i in userData.uploads.indices {
                if (userData.uploads[i].id == decodedResponse.upload_id) {
                    userData.uploads[i].comments.append(decodedResponse)
                }
            }
        } catch {
            
            throw NetworkError.failedDecode
        }
    }
    
    // POST
    func addBucket(userID: String, name: String) async throws {
        let req: BucketReq = BucketReq(name: name)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            
            throw NetworkError.failedEncode
        }
        
        let url = URL(string: "\(host)/api/user/\(userID)/buckets/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        do {
            let (data, _) = try await URLSession.shared.upload(for: request, from: encoded)
            let decodedResponse = try JSONDecoder().decode(Bucket.self, from: data)
            userData.buckets.append(decodedResponse)
        } catch {
            
            throw NetworkError.failedDecode
        }
    }
    
    // GET
    func getBucketContents(uid: String, bucketID: String) async throws {
        let url = URL(string: "\(host)/api/user/\(uid)/bucket/\(bucketID)/")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let decodedResponse = try? JSONDecoder().decode(BucketContents.self, from: data) {
                userData.bucketContents.append(decodedResponse)
            }
        } catch {
            
            throw NetworkError.failedDecode
        }
    }
    
    // GET
    func getBuckets(uid: String) async throws {
        let url = URL(string: "\(host)/api/user/\(uid)/buckets/")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            if let decodedResponse = try? JSONDecoder().decode([Bucket].self, from: data) {
                userData.buckets = decodedResponse
            }
        } catch {
            
            throw NetworkError.failedDecode
        }
    }
    
    
    enum NetworkError: Error {
        case failedEncode
        case failedDecode
        case noReturn
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

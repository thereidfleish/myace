//
//  NetworkController.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/29/21.
//

import Foundation
import Alamofire

class NetworkController: ObservableObject {
    @Published var userData: UserData = UserData(shared: SharedData(id: -1, username: "", display_name: "", email: "", type: -1), uploads: [], buckets: [], friends: [], incomingFriendRequests: [], outgoingFriendRequests: [], bucketContents: BucketContents(id: -1, name: "", user_id: -1, uploads: []))
    @Published var awaiting = false
    @Published var progress: Progress = Progress()
    @Published var uploading = false
    @Published var uploadingStatus = ""
    @Published var uploadURL: URL = URL(fileURLWithPath: "")
     @Published var uploadURLSaved: Bool = false
    @Published var newUser = false
    public let host = "https://api.myace.ai"
    
    
    //    enum State {
    //        case idle
    //        case loading
    //        case failed(Error)
    //        case loaded(UserData)
    //    }
    //
    //    @Published private(set) var state = State.idle
    
    // POST
    func authenticate(token: String, type: Int) async throws {
        let req: AuthReq = AuthReq(token: token, type: type)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            throw NetworkError.failedEncode
        }
        
        let url = URL(string: "\(host)/api/user/authenticate/")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        do {
            let (data, _) = try await URLSession.shared.upload(for: request, from: encoded)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            let decodedResponse = try decoder.decode(SharedData.self, from: data)
            
            DispatchQueue.main.sync {
                userData.shared = decodedResponse
            }
        } catch {
            throw NetworkError.failedDecode
        }
    }
    
    // PUT
    func updateCurrentUser(username: String, displayName: String) async throws {
        let req: UpdateUserReq = UpdateUserReq(username: username, display_name: displayName)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            throw NetworkError.failedEncode
        }
        
        let url = URL(string: "\(host)/users/me/")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        
        do {
            let (data, response) = try await URLSession.shared.upload(for: request, from: encoded)
            print(data.prettyPrintedJSONString)
            print(response)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            if let decodedResponse = try? decoder.decode(SharedData.self, from: data) {
                print(data.prettyPrintedJSONString)
                print(response)
                userData.shared = decodedResponse
            }
        } catch {
            throw NetworkError.failedDecode
        }
    }
    
    // PUT
    func editUpload(uploadID: String, displayTitle: String) async throws {
        let req: EditUploadReq = EditUploadReq(display_title: displayTitle)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            throw NetworkError.failedEncode
        }
        
        let url = URL(string: "\(host)/uploads/\(uploadID)/")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        
        do {
            let (data, response) = try await URLSession.shared.upload(for: request, from: encoded)
            print(data.prettyPrintedJSONString)
            print(response)
        } catch {
            throw NetworkError.failedDecode
        }
    }
    
    // GET
    func getAllUploads(uid: String) async throws {
        let url = URL(string: "\(host)/uploads/")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            if let decodedResponse = try? decoder.decode([Upload].self, from: data) {
                userData.uploads = decodedResponse
            }
        } catch {
            
            throw NetworkError.failedDecode
        }
    }
    
    // GET
    func getUpload(uid: String, uploadID: String) async throws -> Upload {
        let url = URL(string: "\(host)/uploads/\(uploadID)/")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            print(data.prettyPrintedJSONString)
            print(response)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            if let decodedResponse = try? decoder.decode(Upload.self, from: data) {
                let (data, response) = try await URLSession.shared.data(from: URL(string: decodedResponse.url!)!)
                print(data.prettyPrintedJSONString)
                print(response)
                return decodedResponse
            }
        } catch {
            throw NetworkError.failedDecode
        }
        throw NetworkError.noReturn
        //        return Upload(id: -1, created: "?", display_title: "?", stream_ready: false, bucket_id: -1, comments: [], url: "?")
    }
    
    // DELETE
    func deleteUpload(uploadID: String) async throws {
        let url = URL(string: "\(host)/uploads/\(uploadID)/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "DELETE"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print(data.prettyPrintedJSONString)
            print(response)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            if let decodedResponse = try? decoder.decode(DeleteUploadRes.self, from: data) {
                
                print(data.prettyPrintedJSONString)
                print(response)
            }
        } catch {
            throw NetworkError.failedDecode
        }
    }
    
    
    // POST
    func addComment(uploadID: String, authorID: String, text: String) async throws {
        let req: CommentReq = CommentReq(author_id: authorID, text: text)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            
            throw NetworkError.failedEncode
        }
        
        let url = URL(string: "\(host)/uploads/\(uploadID)/comments/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        do {
            let (data, _) = try await URLSession.shared.upload(for: request, from: encoded)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            let decodedResponse = try decoder.decode(Comment.self, from: data)
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
        
        let url = URL(string: "\(host)/buckets/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        do {
            let (data, _) = try await URLSession.shared.upload(for: request, from: encoded)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            let decodedResponse = try decoder.decode(Bucket.self, from: data)
            DispatchQueue.main.sync {
                userData.buckets.append(decodedResponse)
            }
            
        } catch {
            
            throw NetworkError.failedDecode
        }
    }
    
    // GET
    func getBucketContents(uid: String, bucketID: String) async throws {
        let url = URL(string: "\(host)/buckets/\(bucketID)/")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            print(data.prettyPrintedJSONString)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            let decodedResponse = try decoder.decode(BucketContents.self, from: data)
            DispatchQueue.main.sync {
                self.userData.bucketContents = decodedResponse
                self.userData.bucketContents.uploads.sort(by: {$0.created > $1.created})
                print("Got given bucket in nc!")
                //print(self.userData.bucketContents)
            }
            
        } catch {
            throw NetworkError.failedDecode
        }
    }
    
    // GET
    func getBuckets() async throws {
        let url = URL(string: "\(host)/buckets/")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            //print("JSON Data: \(data.prettyPrintedJSONString)")
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            let decodedResponse = try decoder.decode(BucketRes.self, from: data)
            DispatchQueue.main.sync {
                userData.buckets = decodedResponse.buckets
            }
            
        } catch {
            throw NetworkError.failedDecode
        }
    }
    
    // GET
    func getFriends() async throws {
        let url = URL(string: "\(host)/friends/")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(FriendRes.self, from: data)
            DispatchQueue.main.sync {
                userData.friends = decodedResponse.friends
            }
            
        } catch {
            throw NetworkError.failedDecode
        }
    }
    
    // GET
    func getFriendRequests() async throws {
        let url = URL(string: "\(host)/friends/requests/")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(AllFriendRequestsRes.self, from: data)
            DispatchQueue.main.sync {
                userData.incomingFriendRequests = decodedResponse.incoming
                userData.outgoingFriendRequests = decodedResponse.outgoing
            }
            
        } catch {
            throw NetworkError.failedDecode
        }
    }
    
    // POST
    func createFriendRequest(userID: String) async throws {
        let req: FriendRequestReq = FriendRequestReq(user_id: Int(userID)!)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            
            throw NetworkError.failedEncode
        }
        
        let url = URL(string: "\(host)/friends/requests/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        do {
            let (data, _) = try await URLSession.shared.upload(for: request, from: encoded)
            //No response
            
//            let decoder = JSONDecoder()
//            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
//            let decodedResponse = try decoder.decode(Bucket.self, from: data)
//            DispatchQueue.main.sync {
//                userData.buckets.append(decodedResponse)
//            }
            
        } catch {
            
            throw NetworkError.failedDecode
        }
    }
    
    // PUT
    func updateIncomingFriendRequest(status: String, userID: Int) async throws {
        let req: UpdateIncomingFriendRequestReq = UpdateIncomingFriendRequestReq(status: status)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            
            throw NetworkError.failedEncode
        }
        
        let url = URL(string: "\(host)/friends/requests/\(userID)/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        
        do {
            let (data, _) = try await URLSession.shared.upload(for: request, from: encoded)

        } catch {
            
            throw NetworkError.failedDecode
        }
    }
    
    // DELETE
    func deleteOutgoingFriendRequest(userID: Int) async throws {
        let url = URL(string: "\(host)/friends/requests/\(userID)/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "DELETE"
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)

        } catch {
            throw NetworkError.failedDecode
        }
    }
    
    // DELETE
    func removeFriend(userID: Int) async throws {
        let url = URL(string: "\(host)/friends/\(userID)/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "DELETE"
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)

        } catch {
            throw NetworkError.failedDecode
        }
    }
    
    enum NetworkError: Error {
        case failedEncode
        case failedDecode
        case noReturn
        case failedUpload
    }
}

extension DateFormatter {
    static let iso8601Full: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = .current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    static let iso8601withFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
}

extension Data {
    var prettyPrintedJSONString: NSString? { /// NSString gives us a nice sanitized debugDescription
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }
        
        return prettyPrintedString
    }
}

//private extension NetworkController {
//    func authenticationDecode(_ JSONdata: Data) {
//        let decoder = JSONDecoder()
//        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
//        let response: SharedData = (try? decoder.decode(SharedData.self, from: JSONdata)) ?? SharedData(userType: -1, uid: "", display_name: "", email: "")
//        userData.shared = response
//    }
//}

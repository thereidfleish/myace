//
//  NetworkController.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/29/21.
//

import Foundation
import Alamofire

class NetworkController: ObservableObject {
    @Published var userData: UserData = UserData()
    @Published var awaiting = false
    @Published var uploadURL: URL = URL(fileURLWithPath: "")
    @Published var uploadURLSaved: Bool = false
    @Published var newUser = false
    let host = "https://api.myace.ai"
    
    
    //    enum State {
    //        case idle
    //        case loading
    //        case failed(Error)
    //        case loaded(UserData)
    //    }
    //
    //    @Published private(set) var state = State.idle
    
    
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
            print(data.prettyPrintedJSONString!)
            print(response)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            if let decodedResponse = try? decoder.decode(SharedData.self, from: data) {
                print(data.prettyPrintedJSONString!)
                print(response)
                userData.shared = decodedResponse
            }
        } catch {
            throw NetworkError.failedDecode
        }
    }
    
    // PUT
    func editUpload(uploadID: String, displayTitle: String?, bucketID: Int?, visibility: Visibility?) async throws {
        let req: EditUploadReq = EditUploadReq(display_title: displayTitle, bucket_id: bucketID, visibility: visibility)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            throw NetworkError.failedEncode
        }
        
        let url = URL(string: "\(host)/uploads/\(uploadID)/")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        
        do {
            let (data, response) = try await URLSession.shared.upload(for: request, from: encoded)
            print(data.prettyPrintedJSONString!)
            print(response)
        } catch {
            throw NetworkError.failedDecode
        }
    }
    
    // GET
    func getUpload(uploadID: String) async throws -> Upload {
        let url = URL(string: "\(host)/uploads/\(uploadID)/")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            print(data.prettyPrintedJSONString!)
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
        } catch {
            throw NetworkError.failedDecode
        }
    }
    
    // GET
    func getComments(uploadID: String?, courtshipType: CourtshipType?) async throws {
        var url: URL
        if (uploadID != nil && courtshipType != nil) {
            url = URL(string: "\(host)/comments?upload=\(uploadID!)&courtship=\(courtshipType!)")!
        } else if let uploadID = uploadID {
            url = URL(string: "\(host)/comments?upload=\(uploadID)")!
        } else if let courtshipType = courtshipType {
            url = URL(string: "\(host)/comments?courtship=\(courtshipType)")!
        } else {
            url = URL(string: "\(host)/comments/")! // Get a list of comments authored by the current user
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            //print("JSON Data: \(data.prettyPrintedJSONString)")
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            let decodedResponse = try decoder.decode(CommentsRes.self, from: data)
            DispatchQueue.main.sync {
                userData.comments = decodedResponse.comments
            }
            
        } catch {
            throw NetworkError.failedDecode
        }
    }
    
    // POST
    func createComment(uploadID: String, text: String) async throws {
        let req: CreateCommentReq = CreateCommentReq(text: text, upload_id: uploadID)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            
            throw NetworkError.failedEncode
        }
        
        let url = URL(string: "\(host)/comments/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        do {
            let (data, _) = try await URLSession.shared.upload(for: request, from: encoded)
            print(data.prettyPrintedJSONString!)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            let decodedResponse = try decoder.decode(Comment.self, from: data)
            
            userData.comments.append(decodedResponse)
        } catch {
            
            throw NetworkError.failedDecode
        }
    }
    
    // DELETE
    func deleteComment(commentID: String) async throws {
        let url = URL(string: "\(host)/comments/\(commentID)/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "DELETE"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print(data.prettyPrintedJSONString!)
            print(response)
        } catch {
            throw NetworkError.failedDecode
        }
    }
    
    // POST
    func createBucket(name: String) async throws {
        let req: BucketReq = BucketReq(name: name)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            
            throw NetworkError.failedEncode
        }
        
        let url = URL(string: "\(host)/buckets/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        do {
            let (data, response) = try await URLSession.shared.upload(for: request, from: encoded)
            print(data.prettyPrintedJSONString)
            print(response)
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
    func getBuckets(userID: String?) async throws {
        var url: URL
        if let userID = userID {
            url = URL(string: "\(host)/buckets?user=\(userID)")!
        } else {
            url = URL(string: "\(host)/buckets")!
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            print("JSON Data: \(data.prettyPrintedJSONString)")
            //print(response)
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
    
    // PUT
    func editBucket(bucketID: String, newName: String) async throws {
        let req: BucketReq = BucketReq(name: newName)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            throw NetworkError.failedEncode
        }
        
        let url = URL(string: "\(host)/buckets/\(bucketID)/")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        
        do {
            let (data, response) = try await URLSession.shared.upload(for: request, from: encoded)
            print(data.prettyPrintedJSONString!)
            print(response)
        } catch {
            throw NetworkError.failedDecode
        }
    }
    
    // DELETE
    func deleteBucket(bucketID: String) async throws {
        let url = URL(string: "\(host)/buckets/\(bucketID)/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "DELETE"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print(data.prettyPrintedJSONString!)
            print(response)
        } catch {
            throw NetworkError.failedDecode
        }
    }
    
    // GET
    func getUploads(userID: Int?, bucketID: String?) async throws {
        var url: URL
        if (userID != nil && bucketID != nil) {
            url = URL(string: "\(host)/uploads?user=\(userID!)&bucket=\(bucketID!)")!
        } else if let userID = userID {
            url = URL(string: "\(host)/uploads?user=\(userID)")!
        } else if let bucketID = bucketID {
            url = URL(string: "\(host)/uploads?bucket=\(bucketID)")!
        } else {
            url = URL(string: "\(host)/uploads/")!
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            print(response)
            print(data.prettyPrintedJSONString!)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            let decodedResponse = try decoder.decode(UploadsRes.self, from: data)
            DispatchQueue.main.sync {
                //userData.bucketContents = decodedResponse
                //userData.bucketContents.uploads.sort(by: {$0.created > $1.created})
                userData.uploads = decodedResponse.uploads
                print("Got given bucket in nc!")
            }
            
        } catch {
            throw NetworkError.failedDecode
        }
    }
    
    // GET
    func searchUser(query: String) async throws -> [SharedData] {
        let url = URL(string: "\(host)/users/search?q=\(query)")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            print(data.prettyPrintedJSONString!)
            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(SearchRes.self, from: data)
            print("yay")
            return decodedResponse.users
            
        } catch {
            throw NetworkError.failedDecode
        }
        //throw NetworkError.noReturn
    }
    
    // POST
    func createCourtshipRequest(userID: String, type: CourtshipType) async throws {
        let req: CourtshipRequestReq = CourtshipRequestReq(user_id: Int(userID)!, type: type)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            
            throw NetworkError.failedEncode
        }
        print(req)
        let url = URL(string: "\(host)/courtships/requests/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        do {
            let (data, response) = try await URLSession.shared.upload(for: request, from: encoded)
            print(response)
            print(data.prettyPrintedJSONString!)
            
        } catch {
            
            throw NetworkError.failedDecode
        }
    }
    
    // GET
    func getCourtshipRequests(type: CourtshipType?, dir: String, users: String?) async throws {
        var stringBuilder: String = "\(host)/courtships/requests?dir=\(dir)"
        
        if (type != nil) {
            stringBuilder += "&type=\(type!)"
        }
        
        if (users != nil) {
            stringBuilder += "&users=\(users!)"
        }
        
        let url = URL(string: stringBuilder)!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(CourtshipRequestRes.self, from: data)
            DispatchQueue.main.sync {
                if dir == "in" {
                    userData.incomingCourtshipRequests = decodedResponse.requests
                }
                else {
                    userData.outgoingCourtshipRequests = decodedResponse.requests
                }
            }
            
        } catch {
            throw NetworkError.failedDecode
        }
    }
    
    // PUT
    func updateIncomingCourtshipRequest(status: String, otherUserID: String) async throws {
        let req: UpdateIncomingCourtshipRequestReq = UpdateIncomingCourtshipRequestReq(status: status)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            
            throw NetworkError.failedEncode
        }
        
        let url = URL(string: "\(host)/courtships/requests/\(otherUserID)/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        
        do {
            let (data, response) = try await URLSession.shared.upload(for: request, from: encoded)
            print(data)
            print(response)
        } catch {
            
            throw NetworkError.failedDecode
        }
    }
    
    // DELETE
    func deleteOutgoingCourtshipRequest(otherUserID: String) async throws {
        let url = URL(string: "\(host)/courtships/requests/\(otherUserID)/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "DELETE"
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            print(data)
            print(response)
            
        } catch {
            throw NetworkError.failedDecode
        }
    }
    
    // GET
    func getCourtships(type: CourtshipType?, users: String?) async throws {
        var stringBuilder: String = "\(host)/courtships\(type == nil && users == nil ? "" : "?")"
        
        if (type != nil) {
            stringBuilder += "type=\(type!)"
        }
        
        if (users != nil) {
            stringBuilder += "\(type != nil ? "&" : "")users=\(users!)"
        }
        
        let url = URL(string: stringBuilder)!
                
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            print(response)
            print(data.prettyPrintedJSONString!)
            let decoder = JSONDecoder()
            let decodedResponse = try decoder.decode(GetCourtshipsRes.self, from: data)
            DispatchQueue.main.sync {
                userData.courtships = decodedResponse.courtships
            }
            
        } catch {
            throw NetworkError.failedDecode
        }
    }
    
    // DELETE
    func removeCourtship(otherUserID: String) async throws {
        let url = URL(string: "\(host)/courtships/\(otherUserID)/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "DELETE"
        
        do {
            let (_, _) = try await URLSession.shared.data(for: request)
           
            
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

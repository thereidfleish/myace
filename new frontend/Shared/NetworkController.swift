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
    @Published var editUploadID: String = ""
    @Published var errorMessage: String = ""
    let host = "https://api.myace.ai"
    let decoder = JSONDecoder()
    var (data, response): (Data, URLResponse) = (Data(), URLResponse())
        
    //    enum State {
    //        case idle
    //        case loading
    //        case failed(Error)
    //        case loaded(UserData)
    //    }
    //
    //    @Published private(set) var state = State.idle
    
    
    func clearUserData() {
        userData = UserData()
        //UserDefaults.standard.set(Data(), forKey: "appletoken")
    }
    
    // POST
    func login(method: String, email: String?, password: String?, token: String?) async throws {
        let req: LoginReq = LoginReq(method: method, email: email, password: password, token: token)
        guard let encoded = try? JSONEncoder().encode(req) else {
            throw NetworkError.failedEncode
        }
        print(token)
        let url = URL(string: "\(host)/login/")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        do {
            (data, response) = try await URLSession.shared.upload(for: request, from: encoded)
            print(response)
            print(data.prettyPrintedJSONString)
            

            
            // Handle the new user
            if ((response as? HTTPURLResponse)?.statusCode ?? -1 == 201) {
                newUser = true
            }
            // Handle the error case
            else if ((response as? HTTPURLResponse)?.statusCode ?? -1 != 200) {
                throw "\((response as? HTTPURLResponse)?.statusCode ?? -1)"
            }
            
            let decodedResponse = try decoder.decode(SharedData.self, from: data)
            userData.shared = decodedResponse
            userData.loggedIn = true
            
        } catch {
            print(error)
            print("login failed decode")
            let decodedResponse = try decoder.decode(ErrorDecode.self, from: data)
            throw decodedResponse.error + " (error code: \(error))"
        }
    }

    // POST
    func registerWithEmail(username: String, display_name: String, biography: String, email: String, password: String) async throws {
        let req: RegisterEmailReq = RegisterEmailReq(username: username, display_name: display_name, biography: biography, email: email, password: password)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            throw NetworkError.failedEncode
        }
        
        let url = URL(string: "\(host)/register/")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        do {
            (data, response) = try await URLSession.shared.upload(for: request, from: encoded)
            print(response)
            print(data.prettyPrintedJSONString)
            if((response as? HTTPURLResponse)?.statusCode ?? -1 != 201) {
                throw "\((response as? HTTPURLResponse)?.statusCode ?? -1)"
            }
            
        } catch {
            print(error)
            print("registerWithEmail failed decode")
            let decodedResponse = try decoder.decode(ErrorDecode.self, from: data)
            throw decodedResponse.error + " (error code: \(error))"
        }
    }
    
    // GET
    func checkUsername(userName: String) async throws -> (Bool, Bool) {
        let url = URL(string: "\(host)/usernames/\(userName)/check/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        
        do {
            (data, response) = try await URLSession.shared.data(for: request)
            print(data.prettyPrintedJSONString)
            print(response)
            if((response as? HTTPURLResponse)?.statusCode ?? -1 != 200) {
                throw "\((response as? HTTPURLResponse)?.statusCode ?? -1)"
            }
            let decodedResponse = try decoder.decode(CheckUsername.self, from: data)
            return (decodedResponse.valid, decodedResponse.available)
        } catch {
            print("checkUsername failed decode")
            let decodedResponse = try decoder.decode(ErrorDecode.self, from: data)
            throw decodedResponse.error + " (error code: \(error))"
        }
    }
    
    
    // PUT
    func updateCurrentUser(username: String?, displayName: String?, biography: String?) async throws {
        let req: UpdateUserReq = UpdateUserReq(username: username, display_name: displayName, biography: biography)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            throw NetworkError.failedEncode
        }
        
        let url = URL(string: "\(host)/users/me/")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        
        do {
            (data, response) = try await URLSession.shared.upload(for: request, from: encoded)
            print(data.prettyPrintedJSONString!)
            print(response)
            
            if ((response as? HTTPURLResponse)?.statusCode ?? -1 != 200) {
                throw "\((response as? HTTPURLResponse)?.statusCode ?? -1)"
            }
            
            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            let decodedResponse = try decoder.decode(SharedData.self, from: data)
            print(data.prettyPrintedJSONString!)
            
            
            
            userData.shared = decodedResponse
        } catch {
            print("updateCurrentUser failed decode")
            let decodedResponse = try decoder.decode(ErrorDecode.self, from: data)
            throw decodedResponse.error + " (error code: \(error))"
        }
    }
    
    // DELETE
    func deleteCurrentUser() async throws {
        let url = URL(string: "\(host)/users/me/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "DELETE"
        
        do {
            (data, response) = try await URLSession.shared.data(for: request)
            print(data.prettyPrintedJSONString)
            print(response)
            if((response as? HTTPURLResponse)?.statusCode ?? -1 != 204) {
                throw "\((response as? HTTPURLResponse)?.statusCode ?? -1)"
            }
        } catch {
            print("deleteCurrentUser failed decode")
            let decodedResponse = try decoder.decode(ErrorDecode.self, from: data)
            throw decodedResponse.error + " (error code: \(error))"
        }
    }
    
    // PUT
    func editUpload(uploadID: String, displayTitle: String?, bucketID: Int?, visibility: Visibility?) async throws {
        let req: EditUploadReq = EditUploadReq(display_title: displayTitle, bucket_id: bucketID, visibility: visibility != nil ? NewVisibility(default: visibility!.default, also_shared_with: visibility!.also_shared_with.map({$0.id})) : nil)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            throw NetworkError.failedEncode
        }
        
        let url = URL(string: "\(host)/uploads/\(uploadID)/")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "PUT"
        
        do {
            (data, response) = try await URLSession.shared.upload(for: request, from: encoded)
            print(response)
            print(data.prettyPrintedJSONString!)
            
            if((response as? HTTPURLResponse)?.statusCode ?? -1 != 200) {
                throw "\((response as? HTTPURLResponse)?.statusCode ?? -1)"
            }
            
        } catch {
            print("editUpload failed decode")
            let decodedResponse = try decoder.decode(ErrorDecode.self, from: data)
            throw decodedResponse.error + " (error code: \(error))"
        }
    }
    
    // GET
    func getUpload(uploadID: String) async throws -> Upload {
        let url = URL(string: "\(host)/uploads/\(uploadID)/")!
        
        do {
            (data, response) = try await URLSession.shared.data(from: url)
            print(response)
            print(data.prettyPrintedJSONString)
            
            if((response as? HTTPURLResponse)?.statusCode ?? -1 != 200) {
                throw "\((response as? HTTPURLResponse)?.statusCode ?? -1)"
            }
            
            let formatter = DateFormatter.iso8601Full
            formatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
            decoder.dateDecodingStrategy = .formatted(formatter)
            
            
            let decodedResponse = try decoder.decode(Upload.self, from: data)
//            (data, response) = try await URLSession.shared.data(from: URL(string: decodedResponse.url!)!)
//            print(data.prettyPrintedJSONString)
//            print(response)
            
            return decodedResponse
            
        } catch {
            print("getUpload failed decode")
            let decodedResponse = try decoder.decode(ErrorDecode.self, from: data)
            throw decodedResponse.error + " (error code: \(error))"
        }

    }
    
    // DELETE
    func deleteUpload(uploadID: String) async throws {
        let url = URL(string: "\(host)/uploads/\(uploadID)/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "DELETE"
        
        do {
            (data, response) = try await URLSession.shared.data(for: request)
            print(data.prettyPrintedJSONString)
            print(response)
            
            if((response as? HTTPURLResponse)?.statusCode ?? -1 != 204) {
                throw "\((response as? HTTPURLResponse)?.statusCode ?? -1)"
            }
        } catch {
            print("deleteUpload failed decode")
            let decodedResponse = try decoder.decode(ErrorDecode.self, from: data)
            throw decodedResponse.error + " (error code: \(error))"
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
            
            if((response as? HTTPURLResponse)?.statusCode ?? -1 != 200) {
                throw "\((response as? HTTPURLResponse)?.statusCode ?? -1)"
            }
            //print("JSON Data: \(data.prettyPrintedJSONString)")
            
            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            let decodedResponse = try decoder.decode(CommentsRes.self, from: data)
            DispatchQueue.main.sync {
                userData.comments = decodedResponse.comments
            }
            
        } catch {
            print("getComments failed decode")
            let decodedResponse = try decoder.decode(ErrorDecode.self, from: data)
            throw decodedResponse.error + " (error code: \(error))"
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
            
            if((response as? HTTPURLResponse)?.statusCode ?? -1 != 201) {
                throw "\((response as? HTTPURLResponse)?.statusCode ?? -1)"
            }
            
            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            let decodedResponse = try decoder.decode(Comment.self, from: data)
            
            userData.comments.append(decodedResponse)
        } catch {
            print("createComments failed decode")
            let decodedResponse = try decoder.decode(ErrorDecode.self, from: data)
            throw decodedResponse.error + " (error code: \(error))"
        }
    }
    
    // DELETE
    func deleteComment(commentID: String) async throws {
        let url = URL(string: "\(host)/comments/\(commentID)/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "DELETE"
        
        do {
            (data, response) = try await URLSession.shared.data(for: request)
            print(data.prettyPrintedJSONString)
            print(response)
            
            if((response as? HTTPURLResponse)?.statusCode ?? -1 != 204) {
                throw "\((response as? HTTPURLResponse)?.statusCode ?? -1)"
            }
        } catch {
            print("deleteComments failed decode")
            let decodedResponse = try decoder.decode(ErrorDecode.self, from: data)
            throw decodedResponse.error + " (error code: \(error))"
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
            (data, response) = try await URLSession.shared.upload(for: request, from: encoded)
            print(data.prettyPrintedJSONString)
            print(response)
        
            if((response as? HTTPURLResponse)?.statusCode ?? -1 != 201) {
                throw "\((response as? HTTPURLResponse)?.statusCode ?? -1)"
            }
            
            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            let decodedResponse = try decoder.decode(Bucket.self, from: data)
            DispatchQueue.main.sync {
                userData.buckets.append(decodedResponse)
            }
            
        } catch {
            let decodedResponse = try decoder.decode(ErrorDecode.self, from: data)
            throw decodedResponse.error + " (error code: \(error))"
        }
    }
    
    // GET
    func getBuckets(userID: String) async throws {
        var url = URL(string: "\(host)/users/\(userID)/buckets")!
        do {
            (data, response) = try await URLSession.shared.data(from: url)
            print(response)
            print("JSON Data: \(data.prettyPrintedJSONString)")
            
            if((response as? HTTPURLResponse)?.statusCode ?? -1 != 200) {
                throw "\((response as? HTTPURLResponse)?.statusCode ?? -1)"
            }
            
            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            let decodedResponse = try decoder.decode(BucketRes.self, from: data)
            DispatchQueue.main.sync {
                userData.buckets = decodedResponse.buckets
            }
            
        } catch {
            print("getBuckets failed decode")
            let decodedResponse = try decoder.decode(ErrorDecode.self, from: data)
            throw decodedResponse.error + " (error code: \(error))"
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
            (data, response) = try await URLSession.shared.upload(for: request, from: encoded)
            print(data.prettyPrintedJSONString!)
            print(response)
            
            if((response as? HTTPURLResponse)?.statusCode ?? -1 != 200) {
                throw "\((response as? HTTPURLResponse)?.statusCode ?? -1)"
            }
        } catch {
            print("editBucket failed decode")
            let decodedResponse = try decoder.decode(ErrorDecode.self, from: data)
            throw decodedResponse.error + " (error code: \(error))"
        }
    }
    
    // DELETE
    func deleteBucket(bucketID: String) async throws {
        let url = URL(string: "\(host)/buckets/\(bucketID)/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "DELETE"
        
        do {
            (data, response) = try await URLSession.shared.data(for: request)
            print(data.prettyPrintedJSONString)
            print(response)
            if((response as? HTTPURLResponse)?.statusCode ?? -1 != 204) {
                throw "\((response as? HTTPURLResponse)?.statusCode ?? -1)"
            }
        } catch {
            print("deleteBucket failed decode")
            let decodedResponse = try decoder.decode(ErrorDecode.self, from: data)
            throw decodedResponse.error + " (error code: \(error))"
        }
    }
    
    // GET
    func getMyUploads(shared_with_ID: Int?, bucketID: String?) async throws {
        var url: URL
        if (shared_with_ID != nil && bucketID != nil) {
            url = URL(string: "\(host)/users/me/uploads?shared-with=\(shared_with_ID!)&bucket=\(bucketID!)")!
        } else if let shared_with_ID = shared_with_ID {
            url = URL(string: "\(host)/users/me/uploads?shared-with=\(shared_with_ID)")!
        } else if let bucketID = bucketID {
            url = URL(string: "\(host)/users/me/uploads?bucket=\(bucketID)")!
        } else {
            url = URL(string: "\(host)/users/me/uploads")!
        }
        
        do {
            (data, response) = try await URLSession.shared.data(from: url)
            print(response)
            print(data.prettyPrintedJSONString!)
            
            if((response as? HTTPURLResponse)?.statusCode ?? -1 != 200) {
                throw "\((response as? HTTPURLResponse)?.statusCode ?? -1)"
            }
            
            let formatter = DateFormatter.iso8601Full
            formatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
            decoder.dateDecodingStrategy = .formatted(formatter)
            let decodedResponse = try decoder.decode(UploadsRes.self, from: data)
            DispatchQueue.main.sync {
                //userData.bucketContents = decodedResponse
                //userData.bucketContents.uploads.sort(by: {$0.created > $1.created})
                userData.uploads = decodedResponse.uploads
                print("Got given bucket in nc!")
            }
            
        } catch {
            print("getMyUploads failed decode")
            let decodedResponse = try decoder.decode(ErrorDecode.self, from: data)
            throw decodedResponse.error + " (error code: \(error))"
        }
    }
    
    // GET
    func getOtherUserUploads(userID: Int?, bucketID: String?) async throws {
        var url: URL
        if let bucketID = bucketID {
            url = URL(string: "\(host)/users/\(userID!)/uploads?bucket=\(bucketID)")!
        } else {
            url = URL(string: "\(host)/users/\(userID!)/uploads")!
        }
        
        do {
            (data, response) = try await URLSession.shared.data(from: url)
            print(response)
            print(data.prettyPrintedJSONString!)
            
            if((response as? HTTPURLResponse)?.statusCode ?? -1 != 200) {
                throw "\((response as? HTTPURLResponse)?.statusCode ?? -1)"
            }
            
            let formatter = DateFormatter.iso8601Full
            formatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
            decoder.dateDecodingStrategy = .formatted(formatter)
            let decodedResponse = try decoder.decode(UploadsRes.self, from: data)
            DispatchQueue.main.sync {
                //userData.bucketContents = decodedResponse
                //userData.bucketContents.uploads.sort(by: {$0.created > $1.created})
                userData.uploads = decodedResponse.uploads
                print("Got given bucket in nc!")
            }
            
        } catch {
            print("getOtherUserUploads failed decode")
            let decodedResponse = try decoder.decode(ErrorDecode.self, from: data)
            throw decodedResponse.error + " (error code: \(error))"
        }
    }
    
    // GET
    func searchUser(query: String, page: Int) async throws -> ([SharedData], Bool) {
        let url = URL(string: "\(host)/users/search?q=\(query)&page=\(page)")!
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            print(response)
//            if((response as? HTTPURLResponse)?.statusCode ?? -1 == 404) {
//                print("404 return early")
//                return ([], false)
//            }
            
            if((response as? HTTPURLResponse)?.statusCode ?? -1 != 200) {
                throw "\((response as? HTTPURLResponse)?.statusCode ?? -1)"
            }
            
            print(data.prettyPrintedJSONString)
            let decodedResponse = try decoder.decode(SearchRes.self, from: data)
            return (decodedResponse.users, decodedResponse.has_next)
            
        } catch {
            print("searchUser failed decode")
            let decodedResponse = try decoder.decode(ErrorDecode.self, from: data)
            throw decodedResponse.error + " (error code: \(error))"
        }
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
            (data, response) = try await URLSession.shared.upload(for: request, from: encoded)
            print(response)
            print(data.prettyPrintedJSONString)
            
            if((response as? HTTPURLResponse)?.statusCode ?? -1 != 201) {
                throw "\((response as? HTTPURLResponse)?.statusCode ?? -1)"
            }
            
        } catch {
            print("createCourtshipRequest failed decode")
            let decodedResponse = try decoder.decode(ErrorDecode.self, from: data)
            throw decodedResponse.error + " (error code: \(error))"
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
            let (data, response) = try await URLSession.shared.data(from: url)
            if((response as? HTTPURLResponse)?.statusCode ?? -1 != 200) {
                throw "\((response as? HTTPURLResponse)?.statusCode ?? -1)"
            }
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
            print("getCourtshipRequests failed decode")
            let decodedResponse = try decoder.decode(ErrorDecode.self, from: data)
            throw decodedResponse.error + " (error code: \(error))"
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
            (data, response) = try await URLSession.shared.upload(for: request, from: encoded)
            print(data)
            print(response)
            
            if((response as? HTTPURLResponse)?.statusCode ?? -1 != 204) {
                throw "\((response as? HTTPURLResponse)?.statusCode ?? -1)"
            }
        } catch {
            print("updateIncomingCourtshipRequest failed decode")
            let decodedResponse = try decoder.decode(ErrorDecode.self, from: data)
            throw decodedResponse.error + " (error code: \(error))"
        }
    }
    
    // DELETE
    func deleteOutgoingCourtshipRequest(otherUserID: String) async throws {
        let url = URL(string: "\(host)/courtships/requests/\(otherUserID)/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "DELETE"
        
        do {
            (data, response) = try await URLSession.shared.data(for: request)
            print(data)
            print(response)
            if((response as? HTTPURLResponse)?.statusCode ?? -1 != 204) {
                throw "\((response as? HTTPURLResponse)?.statusCode ?? -1)"
            }
        } catch {
            print("deleteOutgoingCourtshipRequest failed decode")
            let decodedResponse = try decoder.decode(ErrorDecode.self, from: data)
            throw decodedResponse.error + " (error code: \(error))"
        }
    }
    
    // GET
    func getCourtships(user_id: String, type: CourtshipType?) async throws {
        var stringBuilder: String = "\(host)/users/\(user_id)/courtships"
        
        if (type != nil) {
            stringBuilder += "?type=\(type!)"
        }
        
        let url = URL(string: stringBuilder)!
                
        do {
            (data, response) = try await URLSession.shared.data(from: url)
            print(response)
            print(data.prettyPrintedJSONString!)
            if((response as? HTTPURLResponse)?.statusCode ?? -1 != 200) {
                throw "\((response as? HTTPURLResponse)?.statusCode ?? -1)"
            }
            
            let decodedResponse = try decoder.decode(GetCourtshipsRes.self, from: data)
            DispatchQueue.main.sync {
                userData.courtships = decodedResponse.courtships
            }
            
        } catch {
            print("getCourtships failed decode")
            let decodedResponse = try decoder.decode(ErrorDecode.self, from: data)
            throw decodedResponse.error + " (error code: \(error))"
        }
    }
    
    // DELETE
    func removeCourtship(otherUserID: String) async throws {
        let url = URL(string: "\(host)/courtships/\(otherUserID)/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "DELETE"
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if((response as? HTTPURLResponse)?.statusCode ?? -1 != 204) {
                throw "\((response as? HTTPURLResponse)?.statusCode ?? -1)"
            }
            
        } catch {
            print("removeCourtship failed decode")
            let decodedResponse = try decoder.decode(ErrorDecode.self, from: data)
            throw decodedResponse.error + " (error code: \(error))"
        }
    }
    
    enum NetworkError: Error {
        case knownError(error: String)
        case failedEncode
        case failedDecode
        case noReturn
        case failedUpload
    }
}

enum CurrentUserAs {
    case student
    case coach
    case observer
}

enum signedInWith {
    case none
    case google
    case apple
    case email
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

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

//private extension NetworkController {
//    func authenticationDecode(_ JSONdata: Data) {
//        let decoder = JSONDecoder()
//        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
//        let response: SharedData = (try? decoder.decode(SharedData.self, from: JSONdata)) ?? SharedData(userType: -1, uid: "", display_name: "", email: "")
//        userData.shared = response
//    }
//}

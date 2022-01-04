//
//  NetworkController.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/29/21.
//

import Foundation
import Alamofire

class NetworkController: ObservableObject {
    @Published var userData: UserData = UserData(shared: SharedData(id: -1, display_name: "", email: "", type: -1), uploads: [], buckets: [], bucketContents: BucketContents(id: -1, name: "", user_id: -1, uploads: []))
    @Published var awaiting = false
    private let host = "https://tennistrainerapi.2h4barifgg1uc.us-east-2.cs.amazonlightsail.com"
    
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
    
    // GET
    func getAllUploads(uid: String) async throws {
        let url = URL(string: "\(host)/api/user/\(uid)/uploads/")!
        
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
        let url = URL(string: "\(host)/api/user/\(uid)/upload/\(uploadID)/")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            if let decodedResponse = try? decoder.decode(Upload.self, from: data) {
                return decodedResponse
            }
        } catch {
            throw NetworkError.failedDecode
        }
        throw NetworkError.noReturn
        //        return Upload(id: -1, created: "?", display_title: "?", stream_ready: false, bucket_id: -1, comments: [], url: "?")
    }
    
    // POST
    func upload(display_title: String, bucket_id: Int, uid: String, fileURL: URL) async throws {
        let req: VideoReq = VideoReq(filename: fileURL.lastPathComponent, display_title: display_title, bucket_id: bucket_id)
        
        guard let encoded = try? JSONEncoder().encode(req) else {
            throw NetworkError.failedEncode
        }
        
        let url = URL(string: "\(host)/api/user/\(uid)/upload/")!
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        
        do {
            let (data, _) = try await URLSession.shared.upload(for: request, from: encoded)
            print(data.prettyPrintedJSONString)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            let decodedResponse = try decoder.decode(VideoRes.self, from: data)
            try await uploadFields(url: decodedResponse.url, fields: decodedResponse.fields, fileURL: fileURL)
        } catch {
            
            throw NetworkError.failedDecode
        }
    }
    
    func uploadFields(url: String, fields: Field, fileURL: URL) async throws {
        let videoData = try! Data(contentsOf: fileURL)
        print(videoData)
        
        AF.upload(multipartFormData: { (multipartFormData) in
            multipartFormData.append(fields.key.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "key")
            multipartFormData.append(fields.x_amz_algorithm.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "x-amz-algorithm")
            multipartFormData.append(fields.x_amz_credential.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "x-amz-credential")
            multipartFormData.append(fields.x_amz_date.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "x-amz-date")
            multipartFormData.append(fields.policy.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "policy")
            multipartFormData.append(fields.x_amz_signature.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "x-amz-signature")
            multipartFormData.append(videoData, withName: "file", fileName: fileURL.lastPathComponent)
            
        }, to: url)
            .uploadProgress { progress in // main queue by default
                print("Upload Progress: \(progress.fractionCompleted)")
                print("Upload Estimated Time Remaining: \(String(describing: progress.estimatedTimeRemaining))")
                print("Upload Total Unit count: \(progress.totalUnitCount)")
                print("Upload Completed Unit Count: \(progress.completedUnitCount)")
            }
            .responseJSON(completionHandler: { response in
                        if response.error != nil {
                        } else {
                            print("FINALY!!!!")
                        }
                    })
        
        //        guard let encoded = try? JSONEncoder().encode(fields) else {
        //            throw NetworkError.failedEncode
        //        }
        //
        //        let boundary = UUID().uuidString
        //
        //        var request = URLRequest(url: URL(string: url)!)
        //        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        ////        request.setValue(fields.key, forHTTPHeaderField: "key")
        ////        request.setValue(fields.x_amz_algorithm, forHTTPHeaderField: "x-amz-algorithm")
        ////        request.setValue(fields.x_amz_credential, forHTTPHeaderField: "x-amz-credential")
        ////        request.setValue(fields.x_amz_date, forHTTPHeaderField: "x-amz-date")
        ////        request.setValue(fields.policy, forHTTPHeaderField: "policy")
        ////        request.setValue(fields.x_amz_signature, forHTTPHeaderField: "x-amz-signature")
        //        request.httpMethod = "POST"
        //        request.httpBody = encoded
        //        print("EEEEKE \(fileURL)")
        //
        //        do {
        //            //let (data, response) = try await URLSession.shared.upload(for: request, from: encoded)
        //            let task = URLSession.shared.uploadTask(with: request, fromFile: fileURL, completionHandler: {data, response, error in
        //                if let data = data {
        //                    print(data.prettyPrintedJSONString ?? "non!e")
        //                    print("RESPONSE: \(response)")
        //                } else {
        //                    print("NOOOO")
        //                }
        //
        //                print("RESPONSE: \(response.debugDescription)")
        //                print("ERROR: \(error)")
        //            })
        //            task.resume()
        //
        ////            let decoder = JSONDecoder()
        ////            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
        ////            let decodedResponse = try decoder.decode(VideoRes.self, from: data)
        //        } catch {
        //
        //            throw NetworkError.failedDecode
        //        }
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
        
        let url = URL(string: "\(host)/api/user/\(userID)/buckets/")!
        
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
        let url = URL(string: "\(host)/api/user/\(uid)/bucket/\(bucketID)/")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            let decodedResponse = try decoder.decode(BucketContents.self, from: data)
            print("Got given bucket!")
            DispatchQueue.main.async {
                self.userData.bucketContents = decodedResponse
                print(self.userData.bucketContents)
            }
            
        } catch {
            throw NetworkError.failedDecode
        }
    }
    
    // GET
    func getBuckets(uid: String) async throws {
        let url = URL(string: "\(host)/api/user/\(uid)/buckets")!
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            
            print("JSON Data: \(data.prettyPrintedJSONString)")
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
            let decodedResponse = try decoder.decode(BucketRes.self, from: data)
            DispatchQueue.main.sync {
                userData.buckets = decodedResponse.buckets
                //self.state = .loaded(self.userData)
            }
            
        } catch {
            //self.state = .failed(NetworkError.failedDecode)
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

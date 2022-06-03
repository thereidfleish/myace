//
//  Data.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/29/21.
//

import Foundation
import UIKit
import AVFoundation

struct UserData {
    // Shared data
    var shared: SharedData = SharedData()
    
    var loggedIn: Bool = false
    
    var profilePic: URL? = nil
    
    // Student data
    //var bucketContents: UploadsRes = UploadsRes()
    
    var buckets: [Bucket] = []
    
    var uploads: [Upload] = []
    
    var comments: [Comment] = []
    
    var courtships: [SharedData] = []
    
    var incomingCourtshipRequests: [SharedData] = []
    
    var outgoingCourtshipRequests: [SharedData] = []
    
//    var incomingFriendRequests: [Friend]
//    var outgoingFriendRequests: [Friend]
    
    //var bucketContents: [BucketContents]
    
    //var bucketContents: BucketContents
    
    //    enum FeedbackStatus {
    //        case awaiting
    //        case read
    //        case unread
    //    }
    //
    //    var feedbacks: [FeedbackStatus] = [.awaiting, .unread, .read]
}

struct Helper {
    static func computeWelcome() -> String {
        let currentHour = Calendar.current.dateComponents([.hour], from: Date())
        
        if currentHour.hour ?? -1 >= 0 && currentHour.hour ?? -1 < 12 {
            return "Good morning,"
        }
        if currentHour.hour ?? -1 >= 12 && currentHour.hour ?? -1 < 18 {
            return "Good afternoon,"
        }
        if currentHour.hour ?? -1 >= 18 && currentHour.hour ?? -1 < 24 {
            return "Good evening,"
        }
        else {
            return "Welcome,"
        }
    }
    
    static func firstName(name: String) -> String {
        let firstSpace = name.firstIndex(of: " ") ?? name.endIndex
        let firstName = name[..<firstSpace]
        return String(firstName)
    }
    
    static func computeErrorMessage(errorMessage: String) -> String {
        return "Error: \(errorMessage).  \(errorMessage.contains("0") ? "JSON Encode Error" : "JSON Decode Error").  Please check your internet connection, log out/log in, or try again later."
    }
    
    static func getThumbnailImage(forUrl url: URL) -> UIImage? {
        let asset: AVAsset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60), actualTime: nil)
            return UIImage(cgImage: thumbnailImage)
        } catch let error {
            print(error)
        }
        
        return nil
    }
}

struct SharedData: Codable, Identifiable, Equatable {
    var id: Int = -1
    var n_courtships: CourtshipTypeQuantity = CourtshipTypeQuantity()
    var username: String = ""
    var display_name: String = ""
    var biography: String = ""
    var courtship: Courtship?
    var n_uploads: Int = -1;
    
    
    //var email: String? = nil
    //var type: Int // -1 == user not logged in, 0 == student, 1 == coach
}

//struct SharedDataRequest: Codable, Identifiable, Equatable {
//    var id: Int = -1
//    var username: String = ""
//    var display_name: String = ""
//    var biography: String = ""
//    var n_uploads: Int = -1;
//    var n_courtships: CourtshipTypeQuantity = CourtshipTypeQuantity()
//    var courtship: Courtship = Courtship(type: .friend)
//    //var email: String? = nil
//    //var type: Int // -1 == user not logged in, 0 == student, 1 == coach
//}

struct Courtship: Codable, Equatable {
    var type: CourtshipType
    var dir: CourtshipRequestDir?
}

enum CourtshipType: String, Codable {
    case friend = "friend"
    case coach = "coach"
    case student = "student"
    case friend_req = "friend-req"
    case coach_req = "coach-req"
    case student_req = "student-req"
}

//enum CourtshipRequestType: String, Codable {
//    case friend = "friend-req"
//    case coach = "coach-req"
//    case student = "student-req"
//}

enum CourtshipRequestDir: String, Codable {
    case `in` = "in"
    case out = "out"
}

struct CourtshipRequestReq: Codable {
    var user_id: Int
    var type: CourtshipType
}

struct CourtshipRequestRes: Codable {
    var requests: [SharedData]
}

struct GetCourtshipsRes: Codable {
    var courtships: [SharedData]
}

//struct Courtship: Codable, Identifiable {
//    var id: Int?
//    var type: String
//    var dir: String?
//    var user: SharedData
//}



//struct CourtshipRequest: Codable {
//    var type: CourtshipRequestType
//    var dir: CourtshipRequestDir
//}

struct UpdateIncomingCourtshipRequestReq: Codable {
    var status: String
}

struct CourtshipTypeQuantity: Codable, Equatable {
    var friends: Int = -1
    var coaches: Int = -1
    var students: Int = -1
}

struct Upload: Codable, Identifiable {
    var id: Int = -1
    var created: Date = Date()
    var display_title: String = ""
    var stream_ready: Bool = false
    var bucket: Bucket = Bucket()
    //var thumbnail: String? = nil
    var visibility: Visibility = Visibility()
    var thumbnail: String? = nil
    var url: String? = nil
    
//    var isVisible: Bool {
//        
//    }
}

struct Visibility: Codable, Equatable {
    var `default`: VisibilityOptions = .private
    var also_shared_with: [SharedData] = []
}

// Used in UploadView
struct NewVisibility: Codable {
    var `default`: VisibilityOptions = .private
    var also_shared_with: [Int] = []
}

enum VisibilityOptions: String, Codable {
    case `private` = "private"
    case coaches_only = "coaches-only"
    case friends_only = "friends-only"
    case friends_and_coaches = "friends-and-coaches"
    case `public` = "public"
}

struct BucketRes: Codable {
    var buckets: [Bucket] = []
}

struct Bucket: Codable, Identifiable {
    var id: Int = -1
    var size: Int = -1
    var last_modified: Date = Date()
    var name: String = ""
}

struct UploadsRes: Codable {
    var uploads: [Upload] = []
}

//struct BucketContents: Codable {
//    var id: Int
//    var name: String
//    var user_id: Int
//    var last_modified: Date?
//    var uploads: [Upload]
//}

//struct Tag: Codable {
//    var tagID: Int = -1
//    var name: String = ""
//}

// Helpers
struct AuthReq: Codable {
    var token: String
    var method: String
}

struct UpdateUserReq: Codable {
    var username: String
    var display_name: String
    var biography: String
}

struct VideoReq: Codable {
    var filename: String
    var display_title: String
    var bucket_id: Int
    var visibility: NewVisibility
}

struct VideoRes: Codable {
    var id: Int
    var url: String
    var fields: Field
}

struct Field: Codable {
    var key: String
    var x_amz_algorithm: String
    var x_amz_credential: String
    var x_amz_date: String
    var policy: String
    var x_amz_signature: String
}

struct Comment: Codable, Identifiable {
    var id: Int = -1
    var created: Date = Date()
    var author: SharedData = SharedData()
    var text: String = ""
    var upload_id: Int = -1
}

struct CreateCommentReq: Codable {
    var text: String
    var upload_id: String
}

struct CommentsRes: Codable {
    var comments: [Comment]
}

struct BucketReq: Codable {
    var name: String
}

struct DeleteUploadRes: Codable {
    var message: String
}

struct SearchRes: Codable {
    var users: [SharedData]
}

struct FriendReq: Codable {
    var courtships: [Courtship]
}



struct EditUploadReq: Codable {
    var display_title: String? = nil
    var bucket_id: Int? = nil
    var visibility: Visibility? = nil
}

struct ErrorDecode: Codable {
    var error: String = ""
}

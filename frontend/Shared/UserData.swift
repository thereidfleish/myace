//
//  Data.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/29/21.
//

import Foundation
import UIKit

struct UserData {
    // Shared data
    var shared: SharedData
    
    var profilePic: URL?
    
    // Student data
    var uploads: [Upload]
    
    var buckets: [Bucket]
    
    //var bucketContents: [BucketContents]
    
    var bucketContents: BucketContents
    
    //    enum FeedbackStatus {
    //        case awaiting
    //        case read
    //        case unread
    //    }
    //
    //    var feedbacks: [FeedbackStatus] = [.awaiting, .unread, .read]
    
    
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
}

struct SharedData: Codable {
    var id: Int
    var display_name: String
    var email: String
    var type: Int // -1 == user not logged in, 0 == student, 1 == coach
}

struct Upload: Codable {
    var id: Int
    var created: Date
    var display_title: String
    var stream_ready: Bool
    var bucket_id: Int
    var comments: [Comment]
    var url: String?
}

struct BucketRes: Codable {
    var buckets: [Bucket]
}

struct Bucket: Codable {
    var id: Int
    var name: String
    var user_id: Int
    var last_modified: Date?
}


struct BucketContents: Codable {
    var id: Int
    var name: String
    var user_id: Int
    var last_modified: Date?
    var uploads: [Upload]
}

struct Comment: Codable {
    var id: Int
    var created: Date
    var author_id: Int
    var upload_id: Int
    var text: String
}

struct Tag: Codable {
    var tagID: Int
    var name: String
}

// Helpers
struct AuthReq: Codable {
    var token: String
    var type: Int
}

struct VideoReq: Codable {
    var filename: String
    var display_title: String
    var bucket_id: Int
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

struct CommentReq: Codable {
    var author_id: String
    var text: String
}

struct BucketReq: Codable {
    var name: String
}

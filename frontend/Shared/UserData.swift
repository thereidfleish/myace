//
//  Data.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/29/21.
//

import Foundation

struct UserData {
    // Shared data
    var shared: SharedData
    
    // Student data
    var uploads: [Upload]
    
//    enum FeedbackStatus {
//        case awaiting
//        case read
//        case unread
//    }
//    
//    var feedbacks: [FeedbackStatus] = [.awaiting, .unread, .read]
    
//    mutating func authenticate(token: String) -> String {
//        userType = 0
//        uid = "hi"
//        display_name = "Reid"
//        email = "me@me.com"
//        return ""
//    }
//
//    func getAllUploads() -> String {
//
//        return ""
//    }
    
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
}

struct SharedData: Codable {
    var id: String
    var display_name: String
    var email: String
    var type: Int // -1 == user not logged in, 0 == student, 1 == coach
}

struct Upload: Codable {
    var uploadID: Int
    var dateCreated: String
    var displayTitle: String
    var streamReady: Bool
    var comments: [Comment]
}

struct Comment: Codable {
    var commentID: Int
    var dateCreated: String
    var authorID: Int
    var upload_id: String
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
}

//struct VideoRes: Codable {
//    var id: String
//    var url: String
//    var fields: Field
//}

//struct Field: Codable {
//    var key: String
//    var x-amz-algorithm: String
//    var x-amz-credential: String
//    var x-amz-date: String
//    var policy: String
//    var x-amz-signature: String
//}

struct CommentReq: Codable {
    var author_id: String
    var text: String
}

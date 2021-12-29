//
//  Data2.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/29/21.
//

import Foundation

//class Data2: ObservableObject {
//    // Shared data
//    @Published var userType: Int = -1; // -1 == user not logged in, 0 == student, 1 == coach
//    @Published var userID: String = ""
//    @Published var displayName: String = ""
//    @Published var email: String = ""
//    
//    // Student data
//    @Published var uploads: [Upload] = []
//    
//    @Published var strokeNames: [String] = ["Backhand Groundstroke", "Forehand Groundstroke", "Backhand Volley"]
//    @Published var trainerNames: [String] = ["David Gries", "Martha Pollack", "David Gries"]
//    @Published var numFeedback: [Int] = [0, 1, 2]
//    @Published var modifyDates: [String] = ["12/25/21", "12/22/21", "12/22/21"]
//    
//    // For the sub-view
//    @Published var modifyDates2: [String] = ["12/25/21", "12/22/21", "12/22/21"]
//    
//    enum FeedbackStatus {
//        case awaiting
//        case read
//        case unread
//    }
//    
//    @Published var feedbacks: [FeedbackStatus] = [.awaiting, .unread, .read]
//    @Published var times: [String] = ["12:18", "1:18", "1:10"]
//    @Published var sizes: [String] = ["3.3 GB", "254 MB", "263.8 MB"]
//    
//    
//    func authenticate(token: String) -> String {
//        userType = 0
//        userID = "hi"
//        displayName = "Reid"
//        email = "me@me.com"
//        return ""
//    }
//    
//    func getAllUploads() -> String {
//        
//        return ""
//    }
//    
//    
//}
//
//class Upload {
//    var uploadID: Int = -1
//    var dateCreated: String = ""
//    var displayTitle: String = ""
//    var streamReady: Bool = false
//    var comments: [Comment] = []
//    
//}
//
//class Comment {
//    var commentID: Int = -1
//    var dateCreated: String = ""
//    var authorID: Int = -1
//    var text: String = ""
//}
//
//class Tag {
//    var tagID: Int = -1
//    var name: String = ""
//}

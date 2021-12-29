//
//  StudentInfo.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/25/21.
//

import Foundation

class StudentInfo: ObservableObject {
    // For the main view
    @Published var strokeNames: [String] = ["Backhand Groundstroke", "Forehand Groundstroke", "Backhand Volley"]
    @Published var trainerNames: [String] = ["David Gries", "Martha Pollack", "David Gries"]
    @Published var numFeedback: [Int] = [0, 1, 2]
    @Published var modifyDates: [String] = ["12/25/21", "12/22/21", "12/22/21"]
    
    // For the sub-view
    @Published var modifyDates2: [String] = ["12/25/21", "12/22/21", "12/22/21"]
    
    enum FeedbackStatus {
        case awaiting
        case read
        case unread
    }
    
    @Published var feedbacks: [FeedbackStatus] = [.awaiting, .unread, .read]
    @Published var times: [String] = ["12:18", "1:18", "1:10"]
    @Published var sizes: [String] = ["3.3 GB", "254 MB", "263.8 MB"]
}

//
//  CoachInfo.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/26/21.
//

import Foundation

class CoachInfo: ObservableObject {
    // For the main view
    @Published var studentNames: [String] = ["Reid Fleishman", "Andrew Chen", "Adam Cahall"]
    @Published var numNewVideos: [Int] = [0, 1, 2]
    @Published var modifyDates: [String] = ["12/22/21", "12/22/21", "12/25/21"]
    
    // For the sub-view
    @Published var strokes: [String] = ["Backhand Groundstroke", "Forehand Groundstroke", "Backhand Volley"]
    @Published var modifyDates2: [String] = ["12/25/21", "12/24/21", "12/22/21"]
    @Published var numNewVideos2: [Int] = [1, 1, 0]
}

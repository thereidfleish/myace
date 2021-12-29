//
//  NetworkRequest.swift
//  AI Tennis Coach
//
//  Created by Reid Fleishman on 12/29/21.
//

import Foundation

class NetworkRequest {
    let url: URLRequest
    
    init(url: URLRequest) {
        self.url = url
    }
    
    func execute(withCompletion completion: @escaping (Data?) -> Void) {
        let task = URLSession.shared.dataTask(with: url, completionHandler: { (data: Data?, _, _) -> Void in
            DispatchQueue.main.async {
                completion(data)
            }
        })
        task.resume()
    }
}

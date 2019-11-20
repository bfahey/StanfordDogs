//
//  Request.swift
//  StanfordDogs
//
//  Created by Blaine Fahey on 11/18/19.
//  Copyright © 2019 Blaine Fahey. All rights reserved.
//

import UIKit
import CoreData

/// Use the `Request` protocol for any resources that can be loaded remotely and processed
/// into their respective response object type.
protocol Request {
    associatedtype ResponseObject
    var url: URL { get set }
    func processData(_ data: Data) throws -> ResponseObject
}

extension Request {
    /// Loads the request using a convenient Swift 5 Result type.
    func load(with session: URLSession = .shared, completion: @escaping (Result<ResponseObject, Error>) -> Void) -> URLSessionDataTask {
        let task = session.dataTask(with: url) { (data, response, error) in
            // Attempt to process the data from the HTTP response and catch any throws.
            let result = Result(catching: { () -> ResponseObject in
                return try self.processData(data ?? Data())
            })
            
            // Call the completion handle from dataTask block which is the URLSession delegate queue.
            completion(result)
        }
        
        task.resume()
        
        return task
    }
}

/// The `ImageRequest` type is used to process images loaded from a remote URL.
struct ImageRequest: Request {
    var url: URL
    
    typealias ResponseObject = UIImage
    
    func processData(_ data: Data) throws -> UIImage {
        guard let image = UIImage(data: data) else {
            throw URLError(.badServerResponse)
        }
        return image
    }
}

/// The `DogAPIRequest` type is used to process JSON responses from Dog API (https://dog.ceo/dog-api/)
struct DogAPIRequest<T: Decodable>: Request {
    var url: URL
        
    typealias ResponseObject = T
    
    func processData(_ data: Data) throws -> T {
        let apiResponse = try JSONDecoder().decode(DogAPIResponse<T>.self, from: data)
        
        return apiResponse.message
    }
}

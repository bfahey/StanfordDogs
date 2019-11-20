//
//  DogAPI.swift
//  StanfordDogs
//
//  Created by Blaine Fahey on 11/18/19.
//  Copyright © 2019 Blaine Fahey. All rights reserved.
//

import CoreData

/// More info at https://dog.ceo/dog-api/
enum DogAPI {

    /// List the main dog breeds.
    static let breedsList: URL = makeDogAPIURL("breeds/list")
    
    /// List the main dog breeds and their subbreeds.
    static let breedListAll: URL = makeDogAPIURL("breeds/list/all")
    
    /// Returns an array of all the images from a breed.
    static func breedImages(for breed: String) -> URL {
        return makeDogAPIURL("breed/\(breed)/images")
    }
    
    /// Use `URLComponents` to generate each API endpoint.
    private static func makeDogAPIURL(_ path: String) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "dog.ceo"
        components.path = "/api/\(path)"
        
        guard let url = components.url else {
            return URL(fileURLWithPath: "")
        }
        
        return url
    }
}

/// A generic Dog API response from the server.
struct DogAPIResponse<MessageObject: Decodable>: Decodable {
    
    enum Status: String, Decodable {
        case success
        case error
    }
    
    enum RootCodingKeys: String, CodingKey {
        case message
        case status
    }
    
    let message: MessageObject
    let status: Status
}

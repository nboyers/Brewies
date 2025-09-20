//
//  APIKeys.swift
//  Brewies
//
//  Created by Noah Boyers on 10/12/23.
//

import Foundation
struct APIResponse: Decodable {
    let statusCode: Int
    let headers: [String: String]
    let body: String
}

struct APIKeys: Decodable {
    let PLACES_API: String
    let placesAPI: String?
    let googlePlacesAPIKey: String?
    
    init(PLACES_API: String, placesAPI: String?, googlePlacesAPIKey: String?) {
        self.PLACES_API = PLACES_API
        self.placesAPI = placesAPI
        self.googlePlacesAPIKey = googlePlacesAPIKey
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try different possible key names for the Places API key
        if let placesAPI = try? container.decode(String.self, forKey: .PLACES_API) {
            self.PLACES_API = placesAPI
        } else if let placesAPI = try? container.decode(String.self, forKey: .placesAPI) {
            self.PLACES_API = placesAPI
        } else if let placesAPI = try? container.decode(String.self, forKey: .googlePlacesAPIKey) {
            self.PLACES_API = placesAPI
        } else {
            throw DecodingError.keyNotFound(CodingKeys.PLACES_API, DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "No Places API key found"))
        }
        
        self.placesAPI = try? container.decode(String.self, forKey: .placesAPI)
        self.googlePlacesAPIKey = try? container.decode(String.self, forKey: .googlePlacesAPIKey)
    }
    
    enum CodingKeys: String, CodingKey {
        case PLACES_API
        case placesAPI
        case googlePlacesAPIKey
    }
}

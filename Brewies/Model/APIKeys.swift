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
    let YELP_API: String
}

//
//  APIKeysViewModel.swift
//  Brewies
//
//  Created by Noah Boyers on 10/12/23.
//

import Foundation
import Alamofire

/// `APIKeysViewModel` is a class responsible for fetching and managing API keys.
class APIKeysViewModel: ObservableObject {
    
    /// Published variable to hold API keys and notify observers about changes.
    @Published var apiKeys: APIKeys? {
        didSet {
            // Cache the apiKeys in memory when they're set.
            self.apiKeysCache = apiKeys
        }
    }
    
    /// Published variable to hold error messages and notify observers about changes.
    @Published var errorMessage: String?
    
    /// Shared instance to allow singleton usage of the class.
    static let shared = APIKeysViewModel()
   
    /// In-memory cache for the API keys.
    private var apiKeysCache: APIKeys?
    
    /// Function to fetch API keys from a specified URL.
    /// - Parameter completion: A closure to be executed once the request is finished, returning optional `APIKeys`.
    func fetchAPIKeys(completion: @escaping (APIKeys?) -> Void) {
        if let cachedKeys = apiKeysCache {
            // If we have cached keys, return them and do not make a network request.
            completion(cachedKeys)
            return
        }
        
        /// Fetch the API key safely.
          guard let apiKey = Bundle.main.infoDictionary?["API_KEY"] as? String else {
              errorMessage = "API Key not found in Info.plist"
              completion(nil)
              return
          }
        
        /// URL string pointing to the API endpoint.
        let urlString = "https://kwahtvg02a.execute-api.us-east-1.amazonaws.com/Prod"
        
        /// HTTP headers to be included in the request, including the API key.
        let headers: HTTPHeaders = ["x-api-key": apiKey]
        
        /// Alamofire request to fetch data from the API.
        AF.request(urlString, headers: headers).response { response in
            switch response.result {
            case .success(let data):
                guard let data = data else {
                    self.errorMessage = "Data is nil"
                    completion(nil)
                    return
                }
                self.decodeAPIResponse(data: data, completion: completion)
            case .failure(let error):
                self.errorMessage = "Error fetching data: \(error)"
                completion(nil)
            }
        }
    }
    

    /// Function to clean a JSON string from unwanted characters.
    /// - Parameter jsonString: The original JSON string.
    /// - Returns: The cleaned JSON string.
    private func cleanJSONString(_ jsonString: String) -> String {
        var cleanedString = jsonString.replacingOccurrences(of: "\\\"", with: "\"")
        cleanedString = cleanedString.replacingOccurrences(of: "\n", with: "")
        cleanedString = cleanedString.replacingOccurrences(of: "\\n", with: "")
        return cleanedString
    }
    
    /// Function to decode the API response and assign the API keys to `apiKeys`.
    /// - Parameters:
    ///   - data: The data returned from the API.
    ///   - completion: A closure to be executed once the decoding is finished, returning optional `APIKeys`.
    private func decodeAPIResponse(data: Data, completion: @escaping (APIKeys?) -> Void) {
        do {
            let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
            guard apiResponse.statusCode == 200 else {
                self.errorMessage = "Failed to fetch API keys: status code \(apiResponse.statusCode)"
                completion(nil)
                return
            }
            
            let cleanedJSONString = cleanJSONString(apiResponse.body)
            guard let bodyData = cleanedJSONString.data(using: .utf8) else {
                self.errorMessage = "Failed to convert cleaned body to data"
                completion(nil)
                return
            }
            
            self.apiKeys = try JSONDecoder().decode(APIKeys.self, from: bodyData)
            completion(self.apiKeys)
        } catch {
            self.errorMessage = "Failed to decode JSON: \(error)"
            completion(nil)
        }
    }
}

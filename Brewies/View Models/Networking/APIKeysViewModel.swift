//
//  APIKeysViewModel.swift
//  Brewies
//
//  Created by Noah Boyers on 10/12/23.
//
import Foundation

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
    
    /// Function to fetch API keys from Info.plist.
    func fetchAPIKeys() async -> APIKeys? {
        if let cachedKeys = apiKeysCache {
            return cachedKeys // Return cached keys to avoid redundant requests
        }
        
        // Read Google Places API key from Info.plist
        guard let placesAPIKey = Bundle.main.object(forInfoDictionaryKey: "GooglePlacesAPIKey") as? String, !placesAPIKey.isEmpty else {
            // Fallback to Secrets if Info.plist key not found
            let keys = APIKeys(
                PLACES_API: Secrets.PLACES_API,
                placesAPI: Secrets.PLACES_API,
                googlePlacesAPIKey: Secrets.PLACES_API
            )
            self.apiKeys = keys
            return keys
        }
        
        let keys = APIKeys(
            PLACES_API: placesAPIKey,
            placesAPI: placesAPIKey,
            googlePlacesAPIKey: placesAPIKey
        )
        
        self.apiKeys = keys
        return keys
    }
    
    /// Function to fetch API keys from remote endpoint.
    private func fetchRemoteAPIKeys() async -> APIKeys? {
        // Fetch the API key safely from Info.plist
        guard let apiKey = Bundle.main.infoDictionary?["API_KEY"] as? String else {
            return nil
        }
        
        // URL string pointing to the API endpoint.
        let urlString = "https://kwahtvg02a.execute-api.us-east-1.amazonaws.com/Prod"
        guard let url = URL(string: urlString) else {
            return nil
        }
        
        // Create the request and add the API key header
        var request = URLRequest(url: url)
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        do {
            // Use URLSession to make the network request
            let (data, response) = try await URLSession.shared.data(for: request)
            
            // Check if the response is valid and the status code is 200
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }
            
            // Decode the response data
            return try await decodeAPIResponse(data: data)
            
        } catch {
            return nil
        }
    }
    
    /// Function to decode the API response and assign the API keys to `apiKeys`.
    /// - Parameter data: The data returned from the API.
    /// - Returns: Optional `APIKeys` if decoding is successful.
    private func decodeAPIResponse(data: Data) async throws -> APIKeys? {
        do {
            let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
            guard apiResponse.statusCode == 200 else {
                self.errorMessage = "Failed to fetch API keys: status code \(apiResponse.statusCode)"
                return nil
            }
            
            let cleanedJSONString = cleanJSONString(apiResponse.body)
            guard let bodyData = cleanedJSONString.data(using: .utf8) else {
                self.errorMessage = "Failed to convert cleaned body to data"
                return nil
            }
            
            // Decode the final APIKeys from the body data
            let keys = try JSONDecoder().decode(APIKeys.self, from: bodyData)
            self.apiKeys = keys
            return keys
        } catch {
            throw error
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
}

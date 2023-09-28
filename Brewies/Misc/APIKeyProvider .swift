//
//  APIKeyProvider .swift
//  Brewies
//
//  Created by Noah Boyers on 9/21/23.
//
//TODO:
import Foundation
//import AWSSystemManager
//
//class APIKeyProvider {
//    
//    static let shared = APIKeyProvider() // Singleton instance
//    
//    var yelpAPIKey: String?
//    var appId: String?
//    var bannerAdKey: String?
//    var rewardAdKey: String?
//    
//    private init() {}
//    
//    func fetchKeys(completion: @escaping (Error?) -> Void) {
//        let ssm = AWSSystemManager.default()
//        
//        let keys = ["YELP_API_KEY", "APP_ID", "BANNER_AD_KEY", "REWARD_AD_KEY"]
//        
//        let dispatchGroup = DispatchGroup()
//        
//        var errors: [Error] = []
//        
//        for key in keys {
//            dispatchGroup.enter()
//            
//            let input = AWSSystemManagerGetParameterRequest()!
//            input.name = key
//            input.withDecryption = true
//            
//            ssm.getParameter(input).continueWith { (task) -> Any? in
//                if let error = task.error {
//                    errors.append(error)
//                }
//                
//                if let result = task.result {
//                    switch key {
//                    case "YELP_API_KEY":
//                        self.yelpAPIKey = result.parameter?.value
//                    case "APP_ID":
//                        self.appId = result.parameter?.value
//                    case "BANNER_AD_KEY":
//                        self.bannerAdKey = result.parameter?.value
//                    case "REWARD_AD_KEY":
//                        self.rewardAdKey = result.parameter?.value
//                    default:
//                        break
//                    }
//                }
//                
//                dispatchGroup.leave()
//                return nil
//            }
//        }
//        
//        dispatchGroup.notify(queue: .main) {
//             completion(errors.isEmpty ? nil : NSError(domain: "APIKeyProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch one or more keys.", "Errors": errors]))
//         }
//    }
//}
//

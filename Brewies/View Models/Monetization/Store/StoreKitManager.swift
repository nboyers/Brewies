//
//  StoreKitManager.swift
//  Brewies
//
//  Created by Noah Boyers on 7/3/23.
//
import Foundation
import StoreKit

public enum StoreError: Error {
    case failedVerification
}

//alias
typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo //The Product.SubscriptionInfo.RenewalInfo provides information about the next subscription renewal period.
typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState // the renewal states of auto-renewable subscriptions.



class StoreKitManager: ObservableObject {
    @Published var storeProducts: [Product] = []
    
    @Published var purchasedCourses : [Product] = []
    @Published var isAdRemovalPurchased: Bool = false
    @Published private(set) var subscriptions: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    @Published private(set) var subscriptionGroupStatus: RenewalState?
    
    var userViewModel = UserViewModel.shared
    var updateListenerTask : Task<Void, Error>? = nil
    // Subscription slots
    let subscriptionSlots = 20
    
    //maintain a plist of products
    private let productDict: [String : String]
    private let subscriptionsDict: [String : String]
    let adRemovalProductId = "com.nobosoftware.removeAds"
    let creditsProductId = "com.nobosoftware.BuyableRequests"
    let favoritesSlotId = "com.nobosoftware.FavoriteSlot"
    
    //Subscription Types
    let yearlyID = "com.nobos.AnnualBrewies"
    let semiYearlyID = "com.nobos.BiannualBrewies"
    let monthlyID = "com.nobosoftware.Brewies"
    
    init() {
        //check the path for the plist
        if let slistPath = Bundle.main.path(forResource: "SubscriptionsList", ofType: "plist"),
           let plist = FileManager.default.contents(atPath: slistPath) {
            subscriptionsDict = (try? PropertyListSerialization.propertyList(from: plist, format: nil) as? [String : String]) ?? [:]
        } else {
            subscriptionsDict = [:]
        }
        
        if let plistPath = Bundle.main.path(forResource: "ProductList", ofType: "plist"),
           //get the list of products
           let plist = FileManager.default.contents(atPath: plistPath) {
            productDict = (try? PropertyListSerialization.propertyList(from: plist, format: nil) as? [String : String]) ?? [:]
        } else {
            productDict = [:]
        }
        
    
        //Start a transaction listener as close to the app launch as possible so you don't miss any transaction
        updateListenerTask = listenForTransactions()
        
        //create async operation
        Task {
            await requestProducts()
            
    
            
            //deliver the products that the customer purchased
            await updateCustomerProductStatus()
        }
    }
    
    //denit transaction listener on exit or app close
    deinit {
        updateListenerTask?.cancel()
    }
    
    
    func checkIfAdsRemoved() async {
        for product in storeProducts {
            if product.id == adRemovalProductId {
                DispatchQueue.main.async {
                    Task {
                        self.isAdRemovalPurchased = (try? await self.isPurchased(product)) ?? false
                    }
                }
                break
            }
        }
    }
    
    
    @Sendable func getCreditsForSubscription(_ productId: String) {
        let defaults = UserDefaults.standard
        
        // Retrieve the current subscription ID
        let currentSubscriptionID = defaults.string(forKey: "CurrentSubscriptionID") ?? ""
        
        // Check if user has already received credits for this purchase
        if defaults.bool(forKey: productId) && productId != creditsProductId {
            print("User has already received credits for this purchase")
            return
        }
        
        // Determine if this is an upgrade
        let isUpgrade = currentSubscriptionID != "" && currentSubscriptionID != productId
        
        switch productId {
        case monthlyID:
            userViewModel.addCredits(25)
            if !isUpgrade {
                CoffeeShopData.shared.addFavoriteSlots(self.subscriptionSlots)
            }
            break
        case semiYearlyID:
            userViewModel.addCredits(40)
            if !isUpgrade {
                CoffeeShopData.shared.addFavoriteSlots(self.subscriptionSlots)
            }
            break
        case yearlyID:
            userViewModel.addCredits(50)
            if !isUpgrade {
                CoffeeShopData.shared.addFavoriteSlots(self.subscriptionSlots)
            }
            break
        case creditsProductId:
            userViewModel.addCredits(5)
            break
        default:
            break
        }
        
        // Save that user has received credits for this purchase
        defaults.set(true, forKey: productId)
        
        // Update the current subscription ID
        defaults.set(productId, forKey: "CurrentSubscriptionID")
    }

    
    
    
    //MARK: listen for transactions - start this early in the app
    func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            //iterate through any transactions that don't come from a direct call to 'purchase()'
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    
                    //the transaction is verified, deliver the content to the user
                    await self.updateCustomerProductStatus()
                    
                    //Always finish a transaction
                    await transaction.finish()
                } catch {
                    // StoreKit has a transaction that fails verification; don't deliver content to the user
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    
    //MARK: request the products in the background
    @MainActor
    func requestProducts() async {
        do {
            //using the Product static method products to retrieve the list of products
            storeProducts = try await Product.products(for: productDict.values)
            
            // request from the app store using the product ids from list
            subscriptions = try await Product.products(for: subscriptionsDict.values)
        } catch {
            print("Failed - error retrieving products \(error)")
        }
    }
    
    
    //MARK: Generics - check the verificationResults
    func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        //check if JWS passes the StoreKit verification
        switch result {
        case .unverified:
            //failed verificaiton
            throw StoreError.failedVerification
        case .verified(let signedType):
            //the result is verified, return the unwrapped value
            return signedType
        }
    }
    
    //MARK: Update the customers products
    @MainActor
    func updateCustomerProductStatus() async {
        var purchasedCourses: [Product] = []
        
        // iterate through all the user's purchased products
        for await result in Transaction.currentEntitlements {
            do {
                // check if transaction is verified
                let transaction = try checkVerified(result)
                
                if transaction.productID == adRemovalProductId {
                    isAdRemovalPurchased = true
                }
                
                if let course = storeProducts.first(where: { $0.id == transaction.productID }) {
                    purchasedCourses.append(course)
                }
                
                
                switch transaction.productType {
                case .autoRenewable:
                    if let subscription = subscriptions.first(where: {$0.id == transaction.productID}) {
                        purchasedSubscriptions.append(subscription)
                    }
                    if UserDefaults.standard.bool(forKey: "isSubscribed") {
                        if let product = storeProducts.first(where: { $0.id == yearlyID }) {
                            purchasedCourses.append(product)
                        } else if let product = storeProducts.first(where: { $0.id == semiYearlyID }) {
                            purchasedCourses.append(product)
                        } else if let product = storeProducts.first(where: { $0.id == monthlyID }) {
                            purchasedCourses.append(product)
                        }
                    }
                default:
                    break
                }
                // finally assign the purchased products
                self.purchasedCourses = purchasedCourses
                
                // Always finish a transaction.
                await transaction.finish()
            } catch {
                // storekit has a transaction that fails verification, don't deliver content to the user
                print("Transaction failed verification")
            }
        }
        handleSubscriptionStatusChange()
    }
    
    
    //MARK: Purchase and returns an optional transaction
    func purchase(_ product: Product) async throws -> Transaction? {
        //make a purchase request - optional parameters available
        let result = try await product.purchase()
        
        // check the results
        switch result {
        case .success(let verificationResult):
            //Transaction will be verified for automatically using JWT(jwsRepresentation) - we can check the result
            let transaction = try checkVerified(verificationResult)
            
            DispatchQueue.main.async {
                switch product.id {
                case self.creditsProductId:
                    self.getCreditsForSubscription(product.id)
                    break
                case self.yearlyID:
                    self.getCreditsForSubscription(product.id)
                case self.semiYearlyID:
                    self.getCreditsForSubscription(product.id)
                    break
                case self.monthlyID:
                    self.getCreditsForSubscription(product.id)
                    break
                case self.favoritesSlotId:
                    CoffeeShopData.shared.addFavoriteSlots(1)
                    break
                default:
                    break
                }
            }
            
            //the transaction is verified, deliver the content to the user
            await updateCustomerProductStatus()
            
            //always finish a transaction - performance
            await transaction.finish()
            
            return transaction
            
        case .userCancelled, .pending:
            return nil
            
        default:
            return nil
        }
    }
    
    
    func handleSubscriptionStatusChange() {
        // Retrieve the user's subscription status from UserDefaults
        let defaults = UserDefaults.standard
        let isSubscribed = defaults.bool(forKey: "isSubscribed")
        
        // Determine the new subscription status
        let newIsSubscribed = purchasedSubscriptions.contains { product in
            return product.id == yearlyID || product.id == semiYearlyID || product.id == monthlyID
        }
        
        if isSubscribed && !newIsSubscribed {
            // User was subscribed but is no longer. Remove slots.
            CoffeeShopData.shared.removeSubscriptionSlots(self.subscriptionSlots)
        } else if !isSubscribed && newIsSubscribed {
            // User was not subscribed but now is. Add slots.
            CoffeeShopData.shared.addFavoriteSlots(self.subscriptionSlots)
        }
        
        // Update the subscription status in UserDefaults
        defaults.set(newIsSubscribed, forKey: "isSubscribed")
    }

    
    //check if product has already been purchased
    func isPurchased(_ product: Product) async throws -> Bool {
        //as we only have one product type grouping .nonconsumable - we check if it belongs to the purchasedCourses which ran init()
        return purchasedCourses.contains(product)
    }
}
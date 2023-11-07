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

typealias RenewalInfo = StoreKit.Product.SubscriptionInfo.RenewalInfo
typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState

class StoreKitManager: ObservableObject {
    @Published var storeProducts: [Product] = []
    @Published var purchasedCourses: [Product] = []
    @Published var isAdRemovalPurchased: Bool = false
    @Published private(set) var subscriptions: [Product] = []
    @Published private(set) var purchasedSubscriptions: [Product] = []
    @Published private(set) var subscriptionGroupStatus: RenewalState?
    
    var userViewModel = UserViewModel.shared
    var updateListenerTask: Task<Void, Error>? = nil
    let subscriptionSlots = 20
    
    // Product and Subscription Identifiers
    let adRemovalProductId = "com.nobosoftware.removeAds"
    let creditsProductId = "com.nobosoftware.BuyableRequests"
    let favoritesSlotId = "com.nobosoftware.FavoriteSlot"
    
    let yearlyID = "com.nobos.AnnualBrewies"
    let semiYearlyID = "com.nobos.Biannual"
    let monthlyID = "com.nobos.Brewies"
    
    private var productDict: [String: String] = [:]
    private var subscriptionsDict: [String: String] = [:]
    private var productLookup: [String: Product] = [:]
    private var subscriptionLookup: [String: Product] = [:]
    
    init() {
        setupProductLists()
        productLookup = Dictionary(uniqueKeysWithValues: storeProducts.map { ($0.id, $0) })
        subscriptionLookup = Dictionary(uniqueKeysWithValues: subscriptions.map { ($0.id, $0) })
        updateListenerTask = listenForTransactions()
        
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
        
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    private func setupProductLists() {
        if let slistPath = Bundle.main.path(forResource: "SubscriptionsList", ofType: "plist"),
           let plist = FileManager.default.contents(atPath: slistPath) {
            subscriptionsDict = (try? PropertyListSerialization.propertyList(from: plist, format: nil) as? [String: String]) ?? [:]
        }
        
        if let plistPath = Bundle.main.path(forResource: "ProductList", ofType: "plist"),
           let plist = FileManager.default.contents(atPath: plistPath) {
            productDict = (try? PropertyListSerialization.propertyList(from: plist, format: nil) as? [String: String]) ?? [:]
        }
    }
    
    func checkIfAdsRemoved() async {
        if let product = storeProducts.first(where: { $0.id == adRemovalProductId }) {
            DispatchQueue.main.async {
                Task {
                    self.isAdRemovalPurchased = (try? await self.isPurchased(product)) ?? false
                }
            }
        }
    }
    
    
    @Sendable func getCreditsForSubscription(_ productId: String) {
        let defaults = UserDefaults.standard
        
        switch productId {
        case monthlyID:
            userViewModel.addCredits(25)
            userViewModel.subscribe(tier: .monthly) // Update the subscription tier here
            CoffeeShopData.shared.addFavoriteSlots(self.subscriptionSlots)
            
        case semiYearlyID:
            userViewModel.addCredits(40)
            userViewModel.subscribe(tier: .semiYearly) // Update the subscription tier here
            CoffeeShopData.shared.addFavoriteSlots(self.subscriptionSlots)
            
        case yearlyID:
            userViewModel.addCredits(50)
            userViewModel.subscribe(tier: .yearly) // Update the subscription tier here
            CoffeeShopData.shared.addFavoriteSlots(self.subscriptionSlots)
            
        case creditsProductId:
            userViewModel.addCredits(5)
            
        default:
            // Handle other products or errors
            break
        }
        
        // Save the subscription status
        defaults.set(true, forKey: productId)
        
        // Update the current subscription ID
        defaults.set(productId, forKey: "CurrentSubscriptionID")
        
        // This should be handled according to the login status of the user to sync credits
        if userViewModel.user.isLoggedIn {
            userViewModel.syncCredits(accountStatus: "signOut")
        } else {
            userViewModel.syncCredits(accountStatus: "login")
        }
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
            //            print("Failed - error retrieving products \(error)")
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
    
    // MARK: Update the customers products
    @MainActor
    func updateCustomerProductStatus() async {
        var purchasedCoursesTemp: [Product] = []
        var transactionsToFinish: [Transaction] = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if transaction.productID == adRemovalProductId {
                    isAdRemovalPurchased = true
                }
                
                if let course = productLookup[transaction.productID] {
                    purchasedCoursesTemp.append(course)
                }
                
                if transaction.productType == .autoRenewable,
                   let subscription = subscriptionLookup[transaction.productID] {
                    purchasedSubscriptions.append(subscription)
                }
                
                // Collect transactions to be finished after the loop
                transactionsToFinish.append(transaction)
            } catch {
                // Handle errors
            }
        }
        
        self.purchasedCourses = purchasedCoursesTemp
        
        // Finish all transactions after updating purchase status to avoid delays
        for transaction in transactionsToFinish {
            await transaction.finish()
        }
        
        handleSubscriptionStatusChange()
    }
    
    // ... (rest of your class code)
    
    
    //MARK: Purchase and returns an optional transaction
    func purchase(_ product: Product) async throws -> Transaction? {
        //make a purchase request - optional parameters available
        let result = try await product.purchase()
        
        // check the results
        switch result {
        case .success(let verificationResult):
            let transaction = try checkVerified(verificationResult)
            
            DispatchQueue.main.async {
                switch product.id {
                case self.creditsProductId:
                    self.getCreditsForSubscription(product.id)
                    break
                    
                case self.yearlyID:
                    self.getCreditsForSubscription(product.id)
                    break
                    
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
        
        // Determine the new subscription status
        let purchasedSubscriptionIDs = purchasedSubscriptions.map { $0.id }
        var newTier: SubscriptionTier? = nil
        
        if purchasedSubscriptionIDs.contains(yearlyID) {
            newTier = .yearly
        } else if purchasedSubscriptionIDs.contains(semiYearlyID) {
            newTier = .semiYearly
        } else if purchasedSubscriptionIDs.contains(monthlyID) {
            newTier = .monthly
        }
        
        if let newTier = newTier {
            // If there is a new tier, save it and update the subscription status to true
            defaults.set(true, forKey: "isSubscribed")
            defaults.set(newTier.rawValue, forKey: UserKeys.subscriptionTier)
            userViewModel.subscribe(tier: newTier)
        } else {
            // If there's no valid subscription, set the status to false and tier to none
            defaults.set(false, forKey: "isSubscribed")
            defaults.set(SubscriptionTier.none.rawValue, forKey: UserKeys.subscriptionTier)
            userViewModel.unsubscribe()
        }
    }
    
    
    
    //check if product has already been purchased
    func isPurchased(_ product: Product) async throws -> Bool {
        return purchasedCourses.contains(product)
    }
}

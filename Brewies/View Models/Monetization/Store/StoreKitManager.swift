//
//  StoreKitManager.swift
//  Brewies
//
//  Created by Noah Boyers on 7/3/23.
//

import StoreKit
import Combine

// Add your RenewalState definition here if it's not already defined elsewhere
typealias RenewalState = StoreKit.Product.SubscriptionInfo.RenewalState

public enum StoreError: Error {
    case failedVerification
}

@MainActor
class StoreKitManager: ObservableObject {
    @Published var storeStatus = StoreStatus()
    
    // Define product identifiers directly in the class
    static let adRemovalProductId = "com.nobosoftware.removeAds"
    static let creditsProductId = "com.nobosoftware.BuyableRequests"
    static let favoritesSlotId = "com.nobosoftware.FavoriteSlot"
    
    static let yearlyID = "com.nobos.AnnualBrewies"
    static let semiYearlyID = "com.nobos.Biannual"
    static let monthlyID = "com.nobos.Brewies"
    
    var userViewModel = UserViewModel.shared
    var updateListenerTask: Task<Void, Error>? = nil
    let subscriptionSlots = 20
    
    var productLookup: [String: Product] = [:]
    var subscriptionLookup: [String: Product] = [:]
    
    private var refreshDataCancellable: AnyCancellable?
    private let refreshDataSubject = PassthroughSubject<Void, Never>()
    
    init() {
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
        setupRefreshDataCancellable()
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    private func setupProductLists() async {
        await requestProducts()
        
        //        DispatchQueue.main.async {
        // Populate lookups after ensuring 'storeProducts' and 'subscriptions' are fetched.
        self.productLookup = Dictionary(uniqueKeysWithValues: self.storeStatus.storeProducts.map { ($0.id, $0) })
        self.subscriptionLookup = Dictionary(uniqueKeysWithValues: self.storeStatus.subscriptions.map { ($0.id, $0) })
        //        }
    }
    
    
    func checkIfAdsRemoved() async {
        if let product = storeStatus.storeProducts.first(where: { $0.id == StoreKitManager.adRemovalProductId }) {
            DispatchQueue.main.async { [self] in
                Task {
                    storeStatus.isAdRemovalPurchased = (try? await self.isPurchased(product)) ?? false
                }
            }
        }
    }
    
    
    func getCreditsForSubscription(_ productId: String) {
        let defaults = UserDefaults.standard
        
        switch productId {
        case StoreKitManager.monthlyID:
            userViewModel.addCredits(25)
            userViewModel.subscribe(tier: .monthly) // Update the subscription tier here
            CoffeeShopData.shared.addFavoriteSlots(self.subscriptionSlots)
            
        case StoreKitManager.semiYearlyID:
            userViewModel.addCredits(40)
            userViewModel.subscribe(tier: .semiYearly) // Update the subscription tier here
            CoffeeShopData.shared.addFavoriteSlots(self.subscriptionSlots)
            
        case StoreKitManager.yearlyID:
            userViewModel.addCredits(50)
            userViewModel.subscribe(tier: .yearly) // Update the subscription tier here
            CoffeeShopData.shared.addFavoriteSlots(self.subscriptionSlots)
            
        case StoreKitManager.creditsProductId:
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
                    let transaction = try await self.checkVerified(result)
                    
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
    func requestProducts() async {
        do {
            // Request only the hardcoded products
            let productIdentifiers: Set<String> = [
                StoreKitManager.adRemovalProductId,
                StoreKitManager.creditsProductId,
                StoreKitManager.favoritesSlotId,
                StoreKitManager.yearlyID,
                StoreKitManager.semiYearlyID,
                StoreKitManager.monthlyID
            ]
            
            // Fetch products using the hardcoded identifiers
            storeStatus.storeProducts = try await Product.products(for: productIdentifiers)
            storeStatus.subscriptions = storeStatus.storeProducts.filter { product in
                productIdentifiers.contains(product.id)
            }
            
            // Create lookups from the fetched products
            productLookup = Dictionary(uniqueKeysWithValues: storeStatus.storeProducts.map { ($0.id, $0) })
            subscriptionLookup = Dictionary(uniqueKeysWithValues: storeStatus.subscriptions.map { ($0.id, $0) })
        } catch {
            // Handle errors appropriately
            print("Failed to retrieve products: \(error)")
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
    func updateCustomerProductStatus() async {
        var purchasedCoursesTemp: [Product] = []
        var transactionsToFinish: [Transaction] = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                
                if transaction.productID == StoreKitManager.adRemovalProductId {
                    storeStatus.isAdRemovalPurchased = true
                }
                
                if let course = productLookup[transaction.productID] {
                    purchasedCoursesTemp.append(course)
                }
                
                if transaction.productType == .autoRenewable,
                   let subscription = subscriptionLookup[transaction.productID] {
                    storeStatus.purchasedSubscriptions.append(subscription)
                }
                
                // Collect transactions to be finished after the loop
                transactionsToFinish.append(transaction)
            } catch {
                // Handle errors
            }
        }
        
        storeStatus.purchasedCourses = purchasedCoursesTemp
        
        // Finish all transactions after updating purchase status to avoid delays
        for transaction in transactionsToFinish {
            await transaction.finish()
        }
        
        handleSubscriptionStatusChange()
    }
    
    private func performRefreshData() async {
        await requestProducts()
        await updateCustomerProductStatus()
        updateListenerTask = listenForTransactions()
    }
    
    //MARK: Purchase and returns an optional transaction
    func purchase(_ product: Product) async throws -> Transaction? {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verificationResult):
            let transaction = try checkVerified(verificationResult)
            await deliverProductFor(transaction)
            return transaction
        case .userCancelled, .pending:
            return nil
        default:
            return nil
        }
    }
    
    // Handle product delivery in a separate method
    private func deliverProductFor(_ transaction: Transaction) async {
        getCreditsForSubscription(transaction.productID)
        await updateCustomerProductStatus()
        await transaction.finish()
    }
    
    // Combine refreshDataSubject setup into its own method
    private func setupRefreshDataCancellable() {
        refreshDataCancellable = refreshDataSubject
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink(receiveValue: refreshData)
    }
    
    // Consolidate updates into a single method
    private func refreshData() {
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    
    func handleSubscriptionStatusChange() {
        // Retrieve the user's subscription status from UserDefaults
        let defaults = UserDefaults.standard
        
        // Determine the new subscription status
        let purchasedSubscriptionIDs = storeStatus.purchasedSubscriptions.map { $0.id }
        var newTier: SubscriptionTier? = nil
        
        if purchasedSubscriptionIDs.contains(StoreKitManager.yearlyID) {
            newTier = .yearly
        } else if purchasedSubscriptionIDs.contains(StoreKitManager.semiYearlyID) {
            newTier = .semiYearly
        } else if purchasedSubscriptionIDs.contains(StoreKitManager.monthlyID) {
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
    
    
    
    func isPurchased(_ product: Product) async throws -> Bool {
        return storeStatus.purchasedCourses.contains(product)
    }
    
    struct StoreStatus {
        var storeProducts: [Product] = []
        var purchasedCourses: [Product] = []
        var isAdRemovalPurchased: Bool = false
        var subscriptions: [Product] = []
        var purchasedSubscriptions: [Product] = []
        var subscriptionGroupStatus: RenewalState?
    }
}

//
//  StoreKitManager.swift
//  Brewies
//
//  Created by Noah Boyers on 7/3/23.
//
//
//  StoreKitManager.swift
//  Brewies
//
//  Created by Noah Boyers on 7/3/23.
//

import StoreKit
import Combine



public enum StoreError: Error {
    case failedVerification
}

@MainActor
class StoreKitManager: ObservableObject {
    @Published var storeStatus = StoreStatus()
    
    // Define product identifiers directly in the class
    static let creditsProductId = "com.nobosoftware.BuyableRequests"
    static let premiumProductId = "com.nobosoftware.PremiumPackage"
    
    var userViewModel = UserViewModel.shared
    var updateListenerTask: Task<Void, Error>? = nil
    
    var productLookup: [String: Product] = [:]
    
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
        
        // Populate lookups after ensuring 'storeProducts' are fetched.
        self.productLookup = Dictionary(uniqueKeysWithValues: self.storeStatus.storeProducts.map { ($0.id, $0) })
    }
    
    func getCreditsForPurchase(_ productId: String) {
        switch productId {
        case StoreKitManager.creditsProductId:
            userViewModel.addCredits(5)
            
        case StoreKitManager.premiumProductId:
            userViewModel.addCredits(50)
            userViewModel.setPremium(true)
            
        default:
            break
        }
        
        // Sync credits to local storage
        userViewModel.syncCredits(accountStatus: "")
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
            // Request credits and premium products
            let productIdentifiers: Set<String> = [
                StoreKitManager.creditsProductId,
                StoreKitManager.premiumProductId
            ]
            
            // Fetch products using the hardcoded identifiers
            storeStatus.storeProducts = try await Product.products(for: productIdentifiers)
            
            // Create lookups from the fetched products
            productLookup = Dictionary(uniqueKeysWithValues: storeStatus.storeProducts.map { ($0.id, $0) })
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
                
                if transaction.productID == StoreKitManager.premiumProductId {
                    storeStatus.isPremiumPurchased = true
                }
                
                if let course = productLookup[transaction.productID] {
                    purchasedCoursesTemp.append(course)
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
        getCreditsForPurchase(transaction.productID)
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
    
    func isPurchased(_ product: Product) async throws -> Bool {
        return storeStatus.purchasedCourses.contains(product)
    }
    
    struct StoreStatus {
        var storeProducts: [Product] = []
        var purchasedCourses: [Product] = []
        var isPremiumPurchased: Bool = false
    }
}

//
//  YelpAPI.swift
//  Brewies
//
//  Created by Noah Boyers on 4/14/23.
//
import Foundation
import Alamofire
import Combine

class YelpAPI : ObservableObject {
    @Published var yelpParam = YelpSearchParams() { didSet { updateParams() } }
    
    var favoriteCoffeeShops: [BrewLocation] = []
    var cancellables: Set<AnyCancellable> = []
    var radiusInMeters: Int = 5000
    var sortBy: String = "distance"
    var price: [String] = []
    var priceForAPI: [Int] = []
     
    init(yelpParams: YelpSearchParams) {
        self.yelpParam = yelpParams
    }
    
    
    private func updateParams() {
        radiusInMeters = yelpParam.radiusInMeters
        sortBy = yelpParam.sortBy
        priceForAPI = yelpParam.priceForAPI
    }
    
    
    // Add excluded chain names here
    private static var chainCompanyNames: Set<String> = [
        "Starbucks", "Starbucks Coffee", "Peets", "Coffee Bean",
        "McDonald's", "Tim Hortons", "Dunkin'",
        "Krispy Kreme", "First Watch", "Caribou Coffee",
        "Dutch Bros. Coffee", "Gloria Jean's", "The Human Bean", "Tully's Coffee",
        "7-Eleven", "The Coffee Bean & Tea Leaf", "Wawa",
        "The Coffee Club", "Costa Coffee", "Coffee Beanery",
        "Panera Bread", "Tropical Smoothie Cafe",
        "Baskin-Robbins", "Einstein Bros. Bagels", "Cinnabon",
        "Au Bon Pain", "Biggby Coffee", "Bruegger's Bagels",
        "Dunn Brothers Coffee", "Intelligentsia Coffee", "It's A Grind Coffee House",
        "La Colombe Coffee Roasters", "PJ's Coffee", "The Scooter's Coffee",
        "I Love NY Pizza Restaurant Bar & Grill", "LongShot Bar & Billiards",
        "Starbucks Reserve Roastery", "Gordan Ramsay Hell's Kitchen",
        "Paris Baguette", "Café Amazon", "Ediya Coffee", "Greggs", "Luckin Coffee",
        "Café Coffee Day", "Caffe Bene", "A Twosome Place", "Tchibo", "85C Bakery Cafe",
        "Caffè Nero", "Angel-in-us", "SPR Coffee", "Hollys", "Insomnia Coffee Company",
        "Coffee Like", "Louisa Coffee", "Coffee Island", "Pret a Manger", "Secret Recipe",
        "Tom N Toms", "Country Style", "Indian Coffee House", "Michel's Patisserie",
        "Mikel Coffee Company", "Highlands Coffee", "Juan Valdez Café", "Second Cup",
        "OldTown White Coffee", "J.CO Donuts", "Havanna", "Barista", "Espresso House",
        "Mugg & Bean", "Illy Caffè", "Robin's Donuts", "The Coffee House", "Café Café",
        "Cofix", "Aroma Espresso Bar", "Coffee Fellows", "Wayne's Coffee", "Jamaica Blue",
        "Esquires", "Coffee Republic", "Coffine Gurunaru", "Pacific Coffee", "Caffè Ritazza",
        "Baker's Dozen Donuts", "Coffee Time", "Coffee World", "Muzz Buzz", "Arabica",
        "Paul Bassett", "Bo's Coffee", "Zarraffas Coffee", "Blue Bottle Coffee", "Philz Coffee",
        "Hudsons Coffee", "Java House", "Vida e Caffè", "Blenz Coffee", "Dôme", "Coffee#1",
        "Figaro Coffee", "Cafe Barbera", "AMT Coffee", "Ya Kun Kaya Toast", "Drunkin'", "Krispy Kreme Doughnuts"
        ,"Joffrey’s Coffee & Tea Company", "Mega Play", "RaceTrac", "Speedway", "Gas station", "IHOP", "Sheetz", "Ciro's Pizza", "Waffle House",
        "Peet's Coffee", "Starbuck's"
    ]
    
    private static var undesiredCatagories : Set<String> = [
        "wine_bars", "bars", "pizza",
        "servicestations","hotdogs","burgers",
        "donuts","caribbean","seafood",
        "irish_pubs", "sandwiches","tradamerican",
        "italian","desserts","vapeshops",
        "salad","newamerican","breakfast_brunch","icecream",
        "grocery","intlgrocery","Food Trucks", "Indian", "Cannabis Dispensaries", "Cannabis Clinics", "candy store"
    ]
    
    private lazy var desiredCatagories : Set<String> = [
        "breweries","brewpubs","beerbar","beergardens","beergarden",
        "beerhall","beertours","wineries","winetastingroom","cideries","distilleries","winetours","pubs","wine_bars"
    ]
    
    func fetchIndependentBrewLocation (
        apiKey: String,
        latitude: Double,
        longitude: Double,
        term: String,
        businessType: String,
        pricing: [Int]? = nil,
        completion: @escaping ([BrewLocation]) -> Void
    ) {
        let url = "https://api.yelp.com/v3/businesses/search"
        var parameters: [String: Any] = [
            "latitude": latitude,
            "longitude": longitude,
            "term" : term,
            "radius": radiusInMeters,
            "categories": businessType,
            "sort_by": sortBy
        ]

        // Determine if the search is for breweries or coffee shops
        let isBrewerySelected = businessType.lowercased() != "coffee"

        if let pricing = pricing {
            let priceParameter = pricing.map { String($0) }.joined(separator: ",")
            parameters["price"] = priceParameter
        }

        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(String(describing: apiKey))"
        ]

        AF.request(url, parameters: parameters, headers: headers).responseDecodable(of: YelpResponse.self) { response in
            switch response.result {
            case .success(let yelpResponse):
                let coffeeShops = self.parseCoffeeShops(businesses: yelpResponse.businesses, isBrewerySelected: isBrewerySelected)
                completion(coffeeShops)
            case .failure(_):
                completion([])
            }
        }
    }

    
    private func parseCoffeeShops(businesses: [YelpBusiness], isBrewerySelected: Bool) -> [BrewLocation] {
        var coffeeShops: [BrewLocation] = []
        for business in businesses where !isExcludedChain(name: business.name, categories: business.categories, isBrewerySelected:  isBrewerySelected) {
            let coffeeShop = BrewLocation(
                id: business.id,
                name: business.name,
                latitude: business.coordinates.latitude,
                longitude: business.coordinates.longitude,
                rating: business.rating,
                reviewCount: business.reviewCount,
                imageURL: business.imageUrl,
                photos: business.photos ?? [],
                address1: business.location.address1,
                address2: business.location.address2,
                city: business.location.city,
                state: business.location.state,
                zipCode: business.location.zipCode,
                displayPhone: business.displayPhone,
                url: business.url,
                transactions: business.transactions,
                hours:  business.hours,
                isClosed: business.isClosed,
                price: business.price,
                review_count: business.reviewCount
            )
            coffeeShops.append(coffeeShop)
        }
        return coffeeShops
    }
    
    func fetchCoffeeShopDetails(id: String, apiKey: String, completion: @escaping (YelpBusiness) -> Void) {
        let url = "https://api.yelp.com/v3/businesses/\(id)"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(String(describing: apiKey))"
        ]
        
        AF.request(url, headers: headers).responseDecodable(of: YelpBusiness.self) { response in
            switch response.result {
            case .success(let yelpBusiness):
                completion(yelpBusiness)
            case .failure(_):
                return
            }
        }
    }
    
    func isExcludedChain(name: String, categories: [Category], isBrewerySelected: Bool) -> Bool {
        let isChain = YelpAPI.chainCompanyNames.contains { name.lowercased().contains($0.lowercased()) }
        
        // Check if the business is in the desired categories (for breweries)
        let isInDesiredCategory = categories.contains { desiredCatagories.contains($0.alias) }
       
        
        if isBrewerySelected {
            // If it's a brewery search, exclude businesses not in desired categories
            return !isInDesiredCategory
        } else {
            // For coffee shop search, exclude chains and businesses in undesired categories
            let isInUndesiredCategory = categories.contains { YelpAPI.undesiredCatagories.contains($0.alias) }
          
            return isChain || isInUndesiredCategory
        }
    }


}

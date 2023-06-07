//
//  YelpAPI.swift
//  Brewies
//
//  Created by Noah Boyers on 4/14/23.
//
import Foundation
import Alamofire

class YelpAPI {
    private let apiKey = Secrets.yelpApiKey
    var favoriteCoffeeShops: [CoffeeShop] = []
    
    // Add excluded chain names here
    private lazy var chainCompanyNames: Set<String> = [
        "Starbucks", "Peets", "Coffee Bean","pizza",
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
        "Baker's Dozen Donuts", "Coffee Time", "Coffee World", "Muzz Buzz", "%Arabica",
        "Paul Bassett", "Bo's Coffee", "Zarraffas Coffee", "Blue Bottle Coffee", "Philz Coffee",
        "Hudsons Coffee", "Java House", "Vida e Caffè", "Blenz Coffee", "Dôme", "Coffee#1",
        "Figaro Coffee", "Cafe Barbera", "AMT Coffee", "Ya Kun Kaya Toast", "Drunkin'", "Krispy Kreme Doughnuts"
        ,"Joffrey’s Coffee & Tea Company","Mega Play", "RaceTrac"
    ]
    
    
    
    func fetchIndependentCoffeeShops(
        term: String = "local coffee shop",
        latitude: Double,
        longitude: Double,
        radius: Int = 7000,
        categories: String = "coffee,coffeeroasteries,coffeeshops",
        sort_by: String = "distance",
        completion: @escaping ([CoffeeShop]) -> Void
    ) {
        let url = "https://api.yelp.com/v3/businesses/search"
        let parameters: [String: Any] = [
            "term": term,
            "latitude": latitude,
            "longitude": longitude,
            "radius": radius,
            "categories": categories,
            "sort_by": sort_by
        ]
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(apiKey)"
        ]
        
        AF.request(url, parameters: parameters, headers: headers).responseDecodable(of: YelpResponse.self) { response in
            print(response)
            switch response.result {
            case .success(let yelpResponse):
                let coffeeShops = self.parseCoffeeShops(businesses: yelpResponse.businesses)
                completion(coffeeShops)
            case .failure(let error):
                print()
                print("Error fetching coffee shops: \(error.localizedDescription)")
                completion([])
            }
        }
    }
    
    func parseCoffeeShops(businesses: [YelpBusiness]) -> [CoffeeShop] {
        var coffeeShops: [CoffeeShop] = []
        print("BUS: \(businesses)")
        for business in businesses where !isExcludedChain(name: business.name) {
            var coffeeShop = CoffeeShop(
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
                hours:  business.hours
            )
            
            if let cachedCoffeeShop = UserCache.shared.getCachedCoffeeShop(id: business.id), cachedCoffeeShop.isFavorite == true {
                coffeeShop.isFavorite = true
                favoriteCoffeeShops.append(coffeeShop)
            }
            
            coffeeShops.append(coffeeShop)
        }
        return coffeeShops
    }
    
    func fetchCoffeeShopDetails(id: String, completion: @escaping (YelpBusiness) -> Void) {
        let url = "https://api.yelp.com/v3/businesses/\(id)"
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(apiKey)"
        ]
        
        AF.request(url, headers: headers).responseDecodable(of: YelpBusiness.self) { response in
            switch response.result {
            case .success(let yelpBusiness):
                print(response)
                completion(yelpBusiness)
            case .failure(let error):
                print("Error fetching coffee shop details: \(error.localizedDescription)")
            }
        }
    }
    
    func isExcludedChain(name: String) -> Bool {
        for chain in chainCompanyNames {
            if name.contains(chain) {
                return true
            }
        }
        return false
    }
}

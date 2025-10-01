//
//  GooglePlacesAPI.swift
//  Brewies
//
//  Created by Noah Boyers on 8/18/24.
//

import Foundation
import Combine


class GooglePlacesAPI: ObservableObject {
    @Published var googlePlacesParams = GooglePlacesSearchParams() { didSet { updateParams() } }

    var favoriteCoffeeShops: [BrewLocation] = []
    var cancellables: Set<AnyCancellable> = []
    var radiusInMeters: Int = 5000
    var sortBy: String = "prominence"
    var priceLevels: [Int] = []

    init(googlePlacesParams: GooglePlacesSearchParams) {
        self.googlePlacesParams = googlePlacesParams
    }

    private func updateParams() {
        radiusInMeters = googlePlacesParams.radiusInMeters
        sortBy = googlePlacesParams.sortBy
        priceLevels = googlePlacesParams.priceLevels
    }

    // Filter out chain establishments and undesired business types
    private static var chainTypes: Set<String> = [
        "establishment", "point_of_interest", "store", "food", "meal_takeaway",
        "meal_delivery", "restaurant", "bakery", "grocery_or_supermarket"
    ]
    
    private static var undesiredTypes: Set<String> = [
        "gas_station", "convenience_store", "pharmacy", "supermarket",
        "fast_food", "meal_takeaway", "meal_delivery", "restaurant",
        "bakery", "grocery_or_supermarket", "store", "establishment"
    ]

    func fetchNearbyPlaces(
        apiKey: String,
        latitude: Double,
        longitude: Double,
        query: String,
        placeType: String = "cafe"
    ) async throws -> [BrewLocation] {
        let url = URL(string: "https://places.googleapis.com/v1/places:searchNearby")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("places.id,places.displayName,places.location,places.rating,places.userRatingCount,places.photos,places.formattedAddress,places.types,places.regularOpeningHours,places.businessStatus,places.priceLevel", forHTTPHeaderField: "X-Goog-FieldMask")
        
        let includedTypes = placeType == "breweries" ? ["bar"] : ["cafe"]
        
        let requestBody: [String: Any] = [
            "includedTypes": includedTypes,
            "maxResultCount": 20,
            "locationRestriction": [
                "circle": [
                    "center": [
                        "latitude": latitude,
                        "longitude": longitude
                    ],
                    "radius": Double(radiusInMeters)
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        print("[GooglePlacesAPI] New API URL: \(url)")
        print("[GooglePlacesAPI] Using radius: \(radiusInMeters), types: \(includedTypes)")

        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Log raw response for debugging
        if let responseString = String(data: data, encoding: .utf8) {
            print("[GooglePlacesAPI] Raw response: \(responseString.prefix(500))")
        }
        
        let response = try JSONDecoder().decode(NewGooglePlacesResponse.self, from: data)
        print("[GooglePlacesAPI] New API returned \(response.places?.count ?? 0) results")
        let filteredResults = parseNewLocations(places: response.places ?? [], placeType: placeType)
        print("[GooglePlacesAPI] After filtering: \(filteredResults.count) results")
        return filteredResults
    }

    private func parseNewLocations(places: [NewGooglePlace], placeType: String) -> [BrewLocation] {
        var locations: [BrewLocation] = []

        for place in places where !isExcludedNewPlace(name: place.displayName?.text ?? "", types: place.types ?? [], placeType: placeType) {
            let location = BrewLocation(
                id: place.id,
                name: place.displayName?.text ?? "Unknown",
                latitude: place.location?.latitude ?? 0,
                longitude: place.location?.longitude ?? 0,
                rating: place.rating,
                userRatingsTotal: place.userRatingCount,
                imageURL: place.photos?.first?.name,
                photos: place.photos?.compactMap { $0.name },
                address: place.formattedAddress,
                phoneNumber: nil,
                website: nil,
                types: place.types,
                openingHours: nil,
                isClosed: place.businessStatus == "CLOSED_TEMPORARILY" || place.businessStatus == "CLOSED_PERMANENTLY",
                priceLevel: place.priceLevel,
                reviews: nil
            )
            locations.append(location)
        }

        return locations
    }
    
    private func isExcludedNewPlace(name: String, types: [String], placeType: String) -> Bool {
        // Exclude specific chains and unwanted business types
        let excludedNames = ["barnes", "noble", "mcdonald", "starbucks", "dunkin", "subway", "walmart", "target"]
        let nameLower = name.lowercased()
        
        if excludedNames.contains(where: { nameLower.contains($0) }) {
            return true
        }
        
        // Exclude unwanted types
        let excludedTypes: Set<String> = [
            "book_store", "fast_food_restaurant", "meal_takeaway", "meal_delivery",
            "restaurant", "grocery_store", "supermarket", "convenience_store",
            "gas_station", "department_store", "shopping_mall"
        ]
        
        return types.contains { excludedTypes.contains($0) }
    }

    private func isExcludedPlace(name: String, types: [String], placeType: String) -> Bool {
        // Define what we want to keep
        let allowedTypes: Set<String> = placeType == "breweries" ?
            ["bar", "pub", "wine_bar", "establishment", "point_of_interest", "food"] :
            ["cafe", "coffee_shop", "establishment", "point_of_interest", "food"]
        
        // All other Google Places API types to exclude
        let excludedTypes: Set<String> = [
            "car_dealer", "car_rental", "car_repair", "car_wash", "electric_vehicle_charging_station", "gas_station", "parking", "rest_stop",
            "corporate_office", "farm", "ranch",
            "art_gallery", "art_studio", "auditorium", "cultural_landmark", "historical_place", "monument", "museum", "performing_arts_theater", "sculpture",
            "library", "preschool", "primary_school", "school", "secondary_school", "university",
            "adventure_sports_center", "amphitheatre", "amusement_center", "amusement_park", "aquarium", "banquet_hall", "barbecue_area", "botanical_garden", "bowling_alley", "casino", "childrens_camp", "comedy_club", "community_center", "concert_hall", "convention_center", "cultural_center", "cycling_park", "dance_hall", "dog_park", "event_venue", "ferris_wheel", "garden", "hiking_area", "historical_landmark", "internet_cafe", "karaoke", "marina", "movie_rental", "movie_theater", "national_park", "night_club", "observation_deck", "off_roading_area", "opera_house", "park", "philharmonic_hall", "picnic_ground", "planetarium", "plaza", "roller_coaster", "skateboard_park", "state_park", "tourist_attraction", "video_arcade", "visitor_center", "water_park", "wedding_venue", "wildlife_park", "wildlife_refuge", "zoo",
            "public_bath", "public_bathroom", "stable",
            "accounting", "atm", "bank",
            "acai_shop", "afghani_restaurant", "african_restaurant", "american_restaurant", "asian_restaurant", "bagel_shop", "bakery", "bar_and_grill", "barbecue_restaurant", "brazilian_restaurant", "breakfast_restaurant", "brunch_restaurant", "buffet_restaurant", "cafeteria", "candy_store", "cat_cafe", "chinese_restaurant", "chocolate_factory", "chocolate_shop", "confectionery", "deli", "dessert_restaurant", "dessert_shop", "diner", "dog_cafe", "donut_shop", "fast_food_restaurant", "fine_dining_restaurant", "food_court", "french_restaurant", "greek_restaurant", "hamburger_restaurant", "ice_cream_shop", "indian_restaurant", "indonesian_restaurant", "italian_restaurant", "japanese_restaurant", "juice_shop", "korean_restaurant", "lebanese_restaurant", "meal_delivery", "meal_takeaway", "mediterranean_restaurant", "mexican_restaurant", "middle_eastern_restaurant", "pizza_restaurant", "ramen_restaurant", "restaurant", "sandwich_shop", "seafood_restaurant", "spanish_restaurant", "steak_house", "sushi_restaurant", "tea_house", "thai_restaurant", "turkish_restaurant", "vegan_restaurant", "vegetarian_restaurant", "vietnamese_restaurant",
            "city_hall", "courthouse", "embassy", "fire_station", "government_office", "local_government_office", "neighborhood_police_station", "police", "post_office",
            "chiropractor", "dental_clinic", "dentist", "doctor", "drugstore", "hospital", "massage", "medical_lab", "pharmacy", "physiotherapist", "sauna", "skin_care_clinic", "spa", "tanning_studio", "wellness_center", "yoga_studio",
            "apartment_building", "apartment_complex", "condominium_complex", "housing_complex",
            "bed_and_breakfast", "budget_japanese_inn", "campground", "camping_cabin", "cottage", "extended_stay_hotel", "farmstay", "guest_house", "hostel", "hotel", "inn", "japanese_inn", "lodging", "mobile_home_park", "motel", "private_guest_room", "resort_hotel", "rv_park",
            "beach",
            "church", "hindu_temple", "mosque", "synagogue",
            "astrologer", "barber_shop", "beautician", "beauty_salon", "body_art_service", "catering_service", "cemetery", "child_care_agency", "consultant", "courier_service", "electrician", "florist", "food_delivery", "foot_care", "funeral_home", "hair_care", "hair_salon", "insurance_agency", "laundry", "lawyer", "locksmith", "makeup_artist", "moving_company", "nail_salon", "painter", "plumber", "psychic", "real_estate_agency", "roofing_contractor", "storage", "summer_camp_organizer", "tailor", "telecommunications_service_provider", "tour_agency", "tourist_information_center", "travel_agency", "veterinary_care",
            "asian_grocery_store", "auto_parts_store", "bicycle_store", "book_store", "butcher_shop", "cell_phone_store", "clothing_store", "convenience_store", "department_store", "discount_store", "electronics_store", "food_store", "furniture_store", "gift_shop", "grocery_store", "hardware_store", "home_goods_store", "home_improvement_store", "jewelry_store", "liquor_store", "market", "pet_store", "shoe_store", "shopping_mall", "sporting_goods_store", "store", "supermarket", "warehouse_store", "wholesaler",
            "arena", "athletic_field", "fishing_charter", "fishing_pond", "fitness_center", "golf_course", "gym", "ice_skating_rink", "playground", "ski_resort", "sports_activity_location", "sports_club", "sports_coaching", "sports_complex", "stadium", "swimming_pool",
            "airport", "airstrip", "bus_station", "bus_stop", "ferry_terminal", "heliport", "international_airport", "light_rail_station", "park_and_ride", "subway_station", "taxi_stand", "train_station", "transit_depot", "transit_station", "truck_stop"
        ]
        
        // Exclude if it has any excluded types AND doesn't have any allowed types
        let hasExcludedType = types.contains { excludedTypes.contains($0) }
        let hasAllowedType = types.contains { allowedTypes.contains($0) }
        
        return hasExcludedType && !hasAllowedType
    }

    func fetchPlaceDetails(id: String, apiKey: String) async throws -> GooglePlaceDetail {
        let url = URL(string: "https://maps.googleapis.com/maps/api/place/details/json")!
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "place_id", value: id),
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "fields", value: "name,rating,formatted_phone_number,formatted_address,geometry,photo,opening_hours,price_level,website")
        ]

        let request = URLRequest(url: components.url!)
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(GooglePlaceDetailResponse.self, from: data)

        return response.result
    }
}

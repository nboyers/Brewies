//
//  SearchCompleter.swift
//  Brewies
//
//  Created by Noah Boyers on 6/22/23.
//

import SwiftUI
import MapKit

class SearchCompleter: NSObject, MKLocalSearchCompleterDelegate, ObservableObject {
    @Published var results = [MKLocalSearchCompletion]()
    @Published var queryFragment: String = "" {
        didSet {
            completer.queryFragment = queryFragment
        }
    }

    var completer: MKLocalSearchCompleter

    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        completer.delegate = self
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.results = completer.results
    }
}

struct AddressSearch: View {
    @ObservedObject var searchCompleter = SearchCompleter()
    @Binding var searchQuery: String

    var body: some View {
        VStack {
            TextField("Enter address", text: $searchQuery, onEditingChanged: { (changed) in
                self.searchCompleter.queryFragment = searchQuery
            })
            List(searchCompleter.results, id: \.title) { result in
                Text(result.title)
            }
        }
    }
}

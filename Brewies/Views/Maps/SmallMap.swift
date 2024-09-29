//
//  SmallMap.swift
//  Brewies
//
//  Created by Noah Boyers on 6/10/23.
//

import SwiftUI
import MapKit

struct SmallMap: View {
    let location: IdentifiableCoordinate
    @State private var region: MKCoordinateRegion
    
    init(coordinate: CLLocationCoordinate2D, name: String) {
        let location = IdentifiableCoordinate(coordinate: coordinate, name: name)
        self.location = location
        self._region = State(initialValue: MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))
    }
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: [location]) { location in
            MapAnnotation(coordinate: location.coordinate) {
                VStack(spacing: 1) {
                    Image(systemName: "mappin")
                        .resizable()
                        .foregroundColor(.red)
                        .frame(width: 15, height: 30)
                    Text(location.name)
                        .font(.body)
                        .shadow(radius: 10)
                        .bold()
                        .foregroundColor(.white)
                }
            }
        }
        .disabled(true) // Disable interaction if needed
    }
}

struct IdentifiableCoordinate: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let name: String
}

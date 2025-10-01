//
//  BrewPreviewList.swift
//  Brewies
//
//  Created by Noah Boyers on 10/1/25.
//
import SwiftUI
import Kingfisher

struct BrewPreviewList: View {
    @Binding var coffeeShops: [BrewLocation]
    @Binding var selectedCoffeeShop: BrewLocation?
    @Binding var showBrewPreview: Bool
    @Binding var activeSheet: ActiveSheet?
    @ObservedObject var userViewModel = UserViewModel.shared
    @EnvironmentObject var selectedCoffeeShopEnv: SelectedCoffeeShop

    var body: some View {
        ForEach(Array(coffeeShops.enumerated()), id: \.element.id) { index, coffeeShop in
            BrewListItem(location: coffeeShop, photoIndex: index, activeSheet: $activeSheet)
                .onTapGesture {
                    selectedCoffeeShopEnv.coffeeShop = coffeeShop
                    activeSheet = .detailBrew
                }
        }
    }
}





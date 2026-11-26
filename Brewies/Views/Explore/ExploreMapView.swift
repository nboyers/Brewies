//
//  ExploreMapView.swift
//  Brewies
//
//  The full-screen map, opened from the Explore feed.
//

import SwiftUI
import MapKit

struct ExploreMapView: View {
    @Bindable var model: ExploreViewModel
    let userCoordinate: CLLocationCoordinate2D?
    let visitedIDs: Set<String>

    @Environment(\.dismiss) private var dismiss

    @State private var position: MapCameraPosition
    @State private var visibleRegion: MKCoordinateRegion?
    @State private var selectedID: Shop.ID?
    @State private var detailShop: Shop?

    init(model: ExploreViewModel, userCoordinate: CLLocationCoordinate2D?, visitedIDs: Set<String>) {
        self.model = model
        self.userCoordinate = userCoordinate
        self.visitedIDs = visitedIDs

        if let center = model.lastSearchCenter ?? userCoordinate {
            let shops = model.shops.filter { !model.hideVisited || !visitedIDs.contains($0.id) }
            let region = MKCoordinateRegion.framing(shops, center: center, fallbackMeters: model.filters.radiusMeters * 2.4, padding: 1.3)
            _position = State(initialValue: .region(region))
        } else {
            _position = State(initialValue: .automatic)
        }
    }

    private var shops: [Shop] {
        model.shops.filter { !model.hideVisited || !visitedIDs.contains($0.id) }
    }

    var body: some View {
        Map(position: $position, selection: $selectedID) {
            UserAnnotation()
            ForEach(shops) { shop in
                Annotation(shop.name, coordinate: shop.coordinate, anchor: .bottom) {
                    CategoryPin(category: shop.category, isVisited: visitedIDs.contains(shop.id))
                }
                .tag(shop.id)
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            visibleRegion = context.region
        }
        .overlay(alignment: .top) { topBar }
        .overlay(alignment: .bottom) { carousel }
        .onChange(of: selectedID) {
            focusOnSelection()
        }
        .sheet(item: $detailShop) { shop in
            NavigationStack {
                ShopDetailView(shop: shop)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { detailShop = nil }
                        }
                    }
            }
            .presentationDetents([.large])
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 44, height: 44)
                        .floatingSurface(in: Circle())
                }
                .accessibilityLabel("Close map")

                Spacer()
            }

            if showSearchHere {
                Button {
                    if let center = visibleRegion?.center { model.search(near: center) }
                } label: {
                    Label("Search this area", systemImage: "arrow.clockwise")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.accent)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .floatingSurface(in: Capsule())
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            } else if model.phase == .loading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Finding shops…")
                        .font(.subheadline.weight(.medium))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .floatingSurface(in: Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .animation(.snappy, value: showSearchHere)
    }

    /// Offer a new search once the map has moved well away from the last searched spot.
    private var showSearchHere: Bool {
        guard let region = visibleRegion, model.phase != .loading else { return false }
        guard let last = model.lastSearchCenter else { return true }
        let moved = CLLocation(latitude: region.center.latitude, longitude: region.center.longitude)
            .distance(from: CLLocation(latitude: last.latitude, longitude: last.longitude))
        return moved > model.filters.radiusMeters * 0.35
    }

    // MARK: - Carousel

    @ViewBuilder
    private var carousel: some View {
        if !shops.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(shops) { shop in
                        Button {
                            detailShop = shop
                        } label: {
                            ShopCard(
                                shop: shop,
                                distance: userCoordinate.map { shop.distance(from: $0) },
                                isVisited: visitedIDs.contains(shop.id)
                            )
                        }
                        .buttonStyle(.plain)
                        .containerRelativeFrame(.horizontal) { width, _ in width - 56 }
                        .id(shop.id)
                    }
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, 20, for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $selectedID)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.bottom, 12)
        }
    }

    private func focusOnSelection() {
        guard let selectedID, let shop = shops.first(where: { $0.id == selectedID }) else { return }
        // Keep the user's zoom, but never stay zoomed out so far that the shop is a dot.
        let maxDelta = 0.04
        let current = visibleRegion?.span ?? MKCoordinateSpan(latitudeDelta: maxDelta, longitudeDelta: maxDelta)
        let span = MKCoordinateSpan(
            latitudeDelta: min(current.latitudeDelta, maxDelta),
            longitudeDelta: min(current.longitudeDelta, maxDelta)
        )
        withAnimation(.smooth) {
            position = .region(MKCoordinateRegion(center: shop.coordinate, span: span))
        }
    }
}

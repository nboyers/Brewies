//
//  ExploreView.swift
//  Brewies
//

import SwiftUI
import SwiftData
import MapKit

/// The home screen: a map pinned at the top and a list of the closest shops below it.
/// The shop at the top of the list is highlighted on the map, with the route and travel time from the user.
struct ExploreView: View {
    @Environment(LocationService.self) private var location
    @Environment(\.openURL) private var openURL

    @Query private var visits: [Visit]
    @Query private var savedShops: [SavedShop]

    @State private var model = ExploreViewModel()
    @State private var travel = TravelStore()
    @State private var position: MapCameraPosition = .automatic
    @State private var scrolledID: Shop.ID?
    @State private var selectedShop: Shop?
    @State private var showMap = false
    @State private var showFilters = false
    @State private var didSearchOnLaunch = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                mapPanel
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 14)

                feed
            }
            .paperBackground()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $selectedShop) { shop in
                ShopDetailView(shop: shop)
            }
        }
        .fullScreenCover(isPresented: $showMap) {
            ExploreMapView(model: model, userCoordinate: location.coordinate, visitedIDs: visitedIDs)
        }
        .sheet(isPresented: $showFilters) {
            FiltersSheet(model: model)
                .presentationDetents([.medium])
        }
        .task {
            location.start()
        }
        .task(id: activeShop?.id) {
            await loadRoute()
        }
        .onChange(of: location.coordinate?.latitude, initial: true) {
            searchOnFirstLocation()
        }
        .onChange(of: model.category) {
            searchAgain()
        }
        .onChange(of: model.filters) {
            searchAgain()
        }
        .onChange(of: model.shops.map(\.id)) {
            scrolledID = visibleShops.first?.id
        }
        .onChange(of: activeShop?.id) {
            focusMap()
        }
    }

    // MARK: - Map panel

    private var mapPanel: some View {
        Map(position: $position) {
            UserAnnotation()

            if let route = activeTravel?.route {
                MapPolyline(route.polyline)
                    .stroke(Theme.accent, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            }

            ForEach(visibleShops) { shop in
                let isActive = shop.id == activeShop?.id
                Annotation(shop.name, coordinate: shop.coordinate, anchor: .bottom) {
                    CategoryPin(category: shop.category, isVisited: visitedIDs.contains(shop.id), isActive: isActive, size: 28)
                        .onTapGesture { scrolledID = shop.id }
                }
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .frame(height: 300)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius + 4, style: .continuous))
        .overlay(alignment: .topLeading) {
            categoryPicker
                .padding(12)
        }
        .overlay(alignment: .topTrailing) {
            Button {
                showMap = true
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 40, height: 40)
                    .floatingSurface(in: Circle())
            }
            .padding(12)
            .accessibilityLabel("Open full map")
        }
        .overlay(alignment: .bottom) {
            // Sits above the Apple Maps logo and legal link, which must stay visible.
            travelPill
                .padding(.horizontal, 12)
                .padding(.bottom, 38)
        }
        .shadow(color: .black.opacity(0.08), radius: 14, y: 6)
    }

    private var categoryPicker: some View {
        HStack(spacing: 4) {
            ForEach(BrewCategory.allCases) { category in
                let isSelected = model.category == category
                Button {
                    model.category = category
                } label: {
                    HStack(spacing: 6) {
                        CategoryIcon(category: category, size: 14)
                        Text(category.title)
                            .font(.footnote.weight(.semibold))
                    }
                    .foregroundStyle(isSelected ? Color.white : Theme.accent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(isSelected ? Theme.accent : Color.clear, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
        .padding(4)
        .floatingSurface(in: Capsule())
    }

    /// Names the highlighted shop and says how long it takes to get there.
    @ViewBuilder
    private var travelPill: some View {
        if let shop = activeShop, let origin = location.coordinate {
            let info = travel.info(for: shop, from: origin)
            HStack(spacing: 10) {
                Image(systemName: info.mode.symbol)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.accent)
                VStack(alignment: .leading, spacing: 1) {
                    Text(shop.name)
                        .font(.footnote.weight(.semibold))
                        .lineLimit(1)
                    Text("\(info.label) · \(shop.distance(from: origin).formattedDistance)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .floatingSurface(in: Capsule())
            .animation(.snappy, value: shop.id)
            .accessibilityElement(children: .combine)
        } else if model.phase == .loading {
            HStack(spacing: 8) {
                ProgressView()
                Text("Finding shops…")
                    .font(.footnote.weight(.medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .floatingSurface(in: Capsule())
        }
    }

    // MARK: - Feed

    private var feed: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                feedHeader
                feedContent

                // Lets the last shop scroll all the way to the top, so it can become the highlighted one.
                Color.clear.frame(height: 320)
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden)
        // The active shop is the one crossing a line a little below the top edge, so it is
        // always a row the user can actually see rather than one scrolled half out of view.
        .scrollPosition(id: $scrolledID, anchor: UnitPoint(x: 0.5, y: 0.18))
        .refreshable {
            searchAgain()
        }
    }

    private var feedHeader: some View {
        SectionHeader(title: model.category == .coffee ? "Closest cafes" : "Closest breweries") {
            Button {
                showFilters = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.body.weight(.medium))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 40, height: 40)
                    .background(Theme.surface, in: Circle())
                    .overlay(Circle().strokeBorder(Color.primary.opacity(0.08)))
            }
            .accessibilityLabel("Filters")
        }
    }

    @ViewBuilder
    private var feedContent: some View {
        if location.coordinate == nil && model.shops.isEmpty {
            locationState
        } else {
            switch model.phase {
            case .idle:
                EmptyView()
            case .loading where visibleShops.isEmpty:
                VStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { _ in
                        placeholderRow
                    }
                }
            case .failed(let message):
                messageCard(title: "Something went wrong", message: message, actionTitle: "Try Again") {
                    searchAgain()
                }
            default:
                if visibleShops.isEmpty {
                    messageCard(
                        title: "No shops here",
                        message: model.filters.independentOnly
                            ? "Try a larger search distance, or turn off “Independent shops only” in Filters."
                            : "Try a larger search distance or open the map to search another area."
                    )
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(visibleShops) { shop in
                            row(for: shop)
                        }
                    }
                    .scrollTargetLayout()
                }
            }
        }
    }

    private func row(for shop: Shop) -> some View {
        let origin = location.coordinate
        return Button {
            selectedShop = shop
        } label: {
            ShopRow(
                shop: shop,
                distance: origin.map { shop.distance(from: $0) },
                travelLabel: origin.map { travel.info(for: shop, from: $0).label },
                myRating: latestRating[shop.id],
                isVisited: visitedIDs.contains(shop.id),
                isSaved: savedIDs.contains(shop.id),
                isActive: shop.id == activeShop?.id
            )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var locationState: some View {
        if location.isDenied {
            messageCard(
                title: "Turn on location",
                message: "Brewies uses your location to find independent shops near you and show how long they take to reach.",
                actionTitle: "Open Settings"
            ) {
                if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
            }
        } else {
            HStack(spacing: 10) {
                ProgressView()
                Text("Finding your location…")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
        }
    }

    private var placeholderRow: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Theme.accent.opacity(0.12))
                .frame(width: 96, height: 96)
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4).fill(Theme.accent.opacity(0.12)).frame(width: 150, height: 16)
                RoundedRectangle(cornerRadius: 4).fill(Theme.accent.opacity(0.08)).frame(width: 100, height: 12)
            }
            Spacer()
        }
        .padding(10)
        .card()
        .accessibilityHidden(true)
    }

    private func messageCard(title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.display(.headline))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .card()
    }

    // MARK: - Data

    private var visibleShops: [Shop] {
        model.shops.filter { !model.hideVisited || !visitedIDs.contains($0.id) }
    }

    /// The shop at the top of the list, falling back to the first shop before the user scrolls.
    private var activeShop: Shop? {
        if let scrolledID, let shop = visibleShops.first(where: { $0.id == scrolledID }) {
            return shop
        }
        return visibleShops.first
    }

    private var activeTravel: TravelInfo? {
        guard let shop = activeShop, let origin = location.coordinate else { return nil }
        return travel.info(for: shop, from: origin)
    }

    private var visitedIDs: Set<String> { Set(visits.map(\.shopID)) }
    private var savedIDs: Set<String> { Set(savedShops.map(\.shopID)) }

    /// The user's most recent rating for each shop they've rated.
    private var latestRating: [String: Int] {
        var result: [String: (date: Date, rating: Int)] = [:]
        for visit in visits where visit.rating > 0 {
            if let existing = result[visit.shopID], existing.date >= visit.visitedAt { continue }
            result[visit.shopID] = (visit.visitedAt, visit.rating)
        }
        return result.mapValues(\.rating)
    }

    // MARK: - Actions

    private func searchOnFirstLocation() {
        guard !didSearchOnLaunch, let coordinate = location.coordinate else { return }
        didSearchOnLaunch = true
        position = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 3_000, longitudinalMeters: 3_000))
        model.search(near: coordinate)
    }

    private func searchAgain() {
        guard let center = model.lastSearchCenter ?? location.coordinate else { return }
        model.search(near: center)
    }

    /// Frames the highlighted shop together with the user so the trip is visible.
    private func focusMap() {
        guard let shop = activeShop else { return }
        var points = [shop.coordinate]
        if let user = location.coordinate { points.append(user) }

        let region = MKCoordinateRegion.framing(coordinates: points, padding: 2.3, minimumSpan: 0.01)
        withAnimation(.smooth) {
            position = .region(region)
        }
    }

    /// Fetches the real route for the highlighted shop once the user pauses on it.
    private func loadRoute() async {
        guard let shop = activeShop, let origin = location.coordinate else { return }
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }
        await travel.load(for: shop, from: origin)
    }
}

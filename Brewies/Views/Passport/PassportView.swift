//
//  PassportView.swift
//  Brewies
//

import SwiftUI
import SwiftData
import MapKit

struct PassportView: View {
    private enum Tab: String, CaseIterable, Identifiable {
        case journal = "Journal"
        case streaks = "Streaks"
        case saved = "Saved"
        case map = "Map"
        case insights = "Insights"

        var id: String { rawValue }

        var systemImage: String {
            switch self {
            case .journal: return "book.closed.fill"
            case .streaks: return "flame.fill"
            case .saved: return "bookmark.fill"
            case .map: return "map.fill"
            case .insights: return "chart.bar.fill"
            }
        }
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var store

    @Query(sort: \Visit.visitedAt, order: .reverse) private var visits: [Visit]
    @Query(sort: \SavedShop.savedAt, order: .reverse) private var savedShops: [SavedShop]

    @State private var tab: Tab = .journal
    @State private var minimumRating = 0
    @State private var detailShop: Shop?
    @State private var editingVisit: Visit?
    @State private var mapSelection: String?
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                header
                tabChips
                content
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .paperBackground()
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(item: $detailShop) { shop in
                ShopDetailView(shop: shop)
            }
            .sheet(item: $editingVisit) { visit in
                LogVisitView(visit: visit)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Passport")
                    .font(.display(.largeTitle, weight: .bold))
                Spacer()
                streakBadge
            }

            HStack(spacing: 0) {
                stat(value: "\(visits.count)", label: "Visits")
                statDivider
                stat(value: "\(uniqueShopCount)", label: "Shops")
                statDivider
                stat(value: averageRating.map { String(format: "%.1f", $0) } ?? "–", label: "Avg rating")
                statDivider
                stat(value: "\(visitsThisMonth)", label: "This month")
            }
            .padding(.vertical, 16)
            .card()
        }
    }

    private func stat(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.display(.title2, weight: .bold))
                .foregroundStyle(Theme.accent)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.08))
            .frame(width: 1, height: 30)
    }

    private var tabChips: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Tab.allCases) { option in
                        Button {
                            tab = option
                        } label: {
                            Chip(title: option.rawValue, systemImage: option.systemImage, isSelected: tab == option)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(tab == option ? .isSelected : [])
                        .id(option)
                    }
                }
            }
            .scrollClipDisabled()
            // Keep the selected chip in view when the row is wider than the screen.
            .onChange(of: tab) {
                withAnimation(.snappy) {
                    proxy.scrollTo(tab, anchor: .center)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .journal: journal
        case .streaks:
            StreaksView(
                summary: streakSummary,
                checkIn: { shop in
                    modelContext.insert(Visit(shop: shop, visitedAt: Date()))
                },
                select: { shop in
                    detailShop = shop
                }
            )
        case .saved: saved
        case .map: historyMap
        case .insights: insights
        }
    }

    // MARK: - Streaks

    private var streakSummary: StreakSummary {
        StreakSummary(visits: visits.map { StreakVisit(shop: Shop(visit: $0), date: $0.visitedAt) })
    }

    /// A glance at the current streak, shown beside the title once the user has one going.
    @ViewBuilder
    private var streakBadge: some View {
        if let top = streakSummary.top, top.current >= 2 {
            Button {
                tab = .streaks
            } label: {
                Label("\(top.current)", systemImage: "flame.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(Color.orange.opacity(0.14), in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(top.current) week streak at \(top.shop.name)")
        }
    }

    // MARK: - Insights

    @ViewBuilder
    private var insights: some View {
        if !store.isPro {
            ProUpsellCard(
                systemImage: "chart.bar.xaxis",
                title: "See your coffee story",
                message: "Pro shows your top-rated shops, your usual orders, and how often you go.",
                action: { showPaywall = true }
            )
        } else if visits.isEmpty {
            emptyState(
                systemImage: "chart.bar",
                title: "No insights yet",
                message: "Log a few visits and your trends will show up here."
            )
        } else {
            InsightsView(visits: visits)
        }
    }

    /// A gentle reminder for free users who have built up a journal worth protecting.
    @ViewBuilder
    private var backupNudge: some View {
        if !store.isPro && visits.count >= 3 {
            Button {
                showPaywall = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "icloud.fill")
                        .font(.title3)
                        .foregroundStyle(Theme.accent)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Keep your journal safe")
                            .font(.subheadline.weight(.semibold))
                        Text("Pro backs it up and syncs it with iCloud.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.tertiary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .card()
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Journal

    @ViewBuilder
    private var journal: some View {
        if visits.isEmpty {
            emptyState(
                systemImage: "book.closed",
                title: "Your journal is empty",
                message: "Open any shop and tap Log a Visit. Your ratings, drinks and photos will collect here."
            )
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    backupNudge
                    ratingFilterChips

                    if filteredVisits.isEmpty {
                        emptyState(
                            systemImage: "star",
                            title: "Nothing rated \(minimumRating)+",
                            message: "Visits you rate \(minimumRating) stars or higher show up here."
                        )
                    }

                    ForEach(monthGroups, id: \.month) { group in
                        Text(group.month.formatted(.dateTime.month(.wide).year()))
                            .font(.display(.title3))
                            .padding(.top, 6)

                        ForEach(group.visits) { visit in
                            Button {
                                editingVisit = visit
                            } label: {
                                VisitCard(visit: visit)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("View Shop", systemImage: "mappin.and.ellipse") {
                                    detailShop = Shop(visit: visit)
                                }
                                Button("Delete Visit", systemImage: "trash", role: .destructive) {
                                    modelContext.delete(visit)
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
    }

    private var ratingFilterChips: some View {
        HStack(spacing: 8) {
            ratingChip(title: "All", minimum: 0)
            ratingChip(title: "4 & up", minimum: 4, systemImage: "star.fill")
            ratingChip(title: "5", minimum: 5, systemImage: "star.fill")
        }
    }

    private func ratingChip(title: String, minimum: Int, systemImage: String? = nil) -> some View {
        Button {
            minimumRating = minimum
        } label: {
            Chip(title: title, systemImage: systemImage, isSelected: minimumRating == minimum)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(minimum == 0 ? "All ratings" : "Rated \(minimum) stars or more")
        .accessibilityAddTraits(minimumRating == minimum ? .isSelected : [])
    }

    private var filteredVisits: [Visit] {
        visits.filter { minimumRating == 0 || $0.rating >= minimumRating }
    }

    private var monthGroups: [(month: Date, visits: [Visit])] {
        let grouped = Dictionary(grouping: filteredVisits) {
            Calendar.current.dateInterval(of: .month, for: $0.visitedAt)?.start ?? $0.visitedAt
        }
        return grouped.keys.sorted(by: >).map { month in
            (month, (grouped[month] ?? []).sorted { $0.visitedAt > $1.visitedAt })
        }
    }

    // MARK: - Saved

    @ViewBuilder
    private var saved: some View {
        let wantToTry = savedShops.filter(\.wantsToTry)
        let favorites = savedShops.filter(\.isFavorite)

        if wantToTry.isEmpty && favorites.isEmpty {
            emptyState(
                systemImage: "bookmark",
                title: "Nothing saved yet",
                message: "Tap Want to Try or Favorite on a shop to keep it here."
            )
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    savedSection("Want to Try", shops: wantToTry)
                    savedSection("Favorites", shops: favorites)
                }
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
    }

    @ViewBuilder
    private func savedSection(_ title: String, shops: [SavedShop]) -> some View {
        if !shops.isEmpty {
            Text(title)
                .font(.display(.title3))
                .padding(.top, 6)

            ForEach(shops) { record in
                let shop = Shop(saved: record)
                Button {
                    detailShop = shop
                } label: {
                    ShopRow(shop: shop, isVisited: visitedIDs.contains(record.shopID), isSaved: false)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Map

    @ViewBuilder
    private var historyMap: some View {
        if mapShops.isEmpty {
            emptyState(
                systemImage: "map",
                title: "Your map is empty",
                message: "Shops you visit or save appear here."
            )
        } else {
            Map(initialPosition: initialMapPosition, selection: $mapSelection) {
                ForEach(mapShops, id: \.shop.id) { entry in
                    Annotation(entry.shop.name, coordinate: entry.shop.coordinate, anchor: .bottom) {
                        CategoryPin(category: entry.shop.category, isVisited: entry.visited)
                    }
                    .tag(entry.shop.id)
                }
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .padding(.bottom, 8)
            .onChange(of: mapSelection) {
                if let id = mapSelection, let entry = mapShops.first(where: { $0.shop.id == id }) {
                    detailShop = entry.shop
                    mapSelection = nil
                }
            }
        }
    }

    /// Fitting a single marker would zoom to street level, so give a lone shop a neighborhood-sized view.
    private var initialMapPosition: MapCameraPosition {
        guard mapShops.count == 1, let only = mapShops.first else { return .automatic }
        return .region(MKCoordinateRegion(center: only.shop.coordinate, latitudinalMeters: 2_000, longitudinalMeters: 2_000))
    }

    /// One entry per shop, preferring "visited" over "saved".
    private var mapShops: [(shop: Shop, visited: Bool)] {
        var entries: [String: (shop: Shop, visited: Bool)] = [:]
        for record in savedShops {
            entries[record.shopID] = (Shop(saved: record), false)
        }
        for visit in visits {
            entries[visit.shopID] = (Shop(visit: visit), true)
        }
        return Array(entries.values)
    }

    // MARK: - Shared

    private func emptyState(systemImage: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 28))
                .foregroundStyle(Theme.accent)
                .frame(width: 68, height: 68)
                .background(Theme.accent.opacity(0.12), in: Circle())
            Text(title)
                .font(.display(.title3))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
    }

    // MARK: - Stats

    private var visitedIDs: Set<String> { Set(visits.map(\.shopID)) }

    private var uniqueShopCount: Int { visitedIDs.count }

    private var averageRating: Double? {
        let rated = visits.map(\.rating).filter { $0 > 0 }
        guard !rated.isEmpty else { return nil }
        return Double(rated.reduce(0, +)) / Double(rated.count)
    }

    private var visitsThisMonth: Int {
        visits.filter { Calendar.current.isDate($0.visitedAt, equalTo: Date(), toGranularity: .month) }.count
    }
}

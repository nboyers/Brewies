//
//  ShopDetailView.swift
//  Brewies
//

import SwiftUI
import SwiftData
import MapKit

struct ShopDetailView: View {
    let shop: Shop

    @Environment(\.openURL) private var openURL
    @Environment(\.modelContext) private var modelContext

    @Query private var visits: [Visit]
    @Query private var savedRecords: [SavedShop]

    @State private var showLogVisit = false
    @State private var editingVisit: Visit?

    init(shop: Shop) {
        self.shop = shop
        let id = shop.id
        _visits = Query(filter: #Predicate<Visit> { $0.shopID == id }, sort: \Visit.visitedAt, order: .reverse)
        _savedRecords = Query(filter: #Predicate<SavedShop> { $0.shopID == id })
    }

    private var saved: SavedShop? { savedRecords.first }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                hero
                titleBlock
                quickActions
                saveControls

                if !visits.isEmpty {
                    visitHistory
                }

                locationPreview
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .paperBackground()
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { logVisitBar }
        .sheet(isPresented: $showLogVisit) {
            LogVisitView(shop: shop)
        }
        .sheet(item: $editingVisit) { visit in
            LogVisitView(visit: visit)
        }
    }

    // MARK: - Sections

    private var hero: some View {
        ShopImage(shop: shop)
            .frame(height: 220)
            .frame(maxWidth: .infinity)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(alignment: .topLeading) {
                HStack(spacing: 6) {
                    CategoryIcon(category: shop.category, size: 14)
                    Text(shop.category.placeName)
                        .font(.footnote.weight(.semibold))
                }
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .floatingSurface(in: Capsule())
                .padding(12)
            }
            .shadow(color: .black.opacity(0.08), radius: 14, y: 6)
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(shop.name)
                .font(.display(.largeTitle, weight: .bold))
                .fixedSize(horizontal: false, vertical: true)

            if let address = shop.address {
                Label(address, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            if let url = shop.directionsURL {
                Button {
                    openURL(url)
                } label: {
                    QuickActionLabel(title: "Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                }
            }
            if let url = shop.phoneURL {
                Button {
                    openURL(url)
                } label: {
                    QuickActionLabel(title: "Call", systemImage: "phone.fill")
                }
            }
            if let url = shop.website {
                Button {
                    openURL(url)
                } label: {
                    QuickActionLabel(title: "Website", systemImage: "safari.fill")
                }
            }
            ShareLink(item: shop.shareURL, subject: Text(shop.name), message: Text(shop.shareMessage)) {
                QuickActionLabel(title: "Share", systemImage: "square.and.arrow.up")
            }
        }
        .buttonStyle(.plain)
    }

    private var saveControls: some View {
        HStack(spacing: 10) {
            saveToggle(title: "Want to Try", systemImage: "bookmark", filledImage: "bookmark.fill", isOn: saved?.wantsToTry ?? false) {
                update { $0.wantsToTry.toggle() }
            }
            saveToggle(title: "Favorite", systemImage: "heart", filledImage: "heart.fill", isOn: saved?.isFavorite ?? false) {
                update { $0.isFavorite.toggle() }
            }
        }
    }

    private func saveToggle(title: String, systemImage: String, filledImage: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: isOn ? filledImage : systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isOn ? Color.white : Theme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(isOn ? Theme.accent : Theme.surface, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.primary.opacity(isOn ? 0 : 0.08)))
        }
        .buttonStyle(.plain)
        .accessibilityValue(isOn ? "On" : "Off")
    }

    private var visitHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Your visits")

            VStack(spacing: 0) {
                ForEach(visits) { visit in
                    Button {
                        editingVisit = visit
                    } label: {
                        VisitRow(visit: visit)
                            .padding(14)
                    }
                    .buttonStyle(.plain)

                    if visit.id != visits.last?.id {
                        Divider().padding(.leading, 14)
                    }
                }
            }
            .card()
        }
    }

    private var locationPreview: some View {
        Map(initialPosition: .region(MKCoordinateRegion(center: shop.coordinate, latitudinalMeters: 700, longitudinalMeters: 700)), interactionModes: []) {
            Annotation(shop.name, coordinate: shop.coordinate, anchor: .bottom) {
                CategoryPin(category: shop.category, isVisited: !visits.isEmpty)
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .frame(height: 170)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
        .accessibilityHidden(true)
    }

    private var logVisitBar: some View {
        Button {
            showLogVisit = true
        } label: {
            Label(visits.isEmpty ? "Log a Visit" : "Log Another Visit", systemImage: "plus")
        }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(.bar)
    }

    // MARK: - Saving

    /// Applies a change to the saved record, creating it on first use and removing it when both flags are off.
    private func update(_ change: (SavedShop) -> Void) {
        let record = saved ?? {
            let new = SavedShop(shop: shop)
            modelContext.insert(new)
            return new
        }()
        change(record)
        if !record.wantsToTry && !record.isFavorite {
            modelContext.delete(record)
        }
    }
}

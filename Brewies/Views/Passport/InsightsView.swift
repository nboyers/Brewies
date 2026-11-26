//
//  InsightsView.swift
//  Brewies
//
//  Pro: a summary of the user's journal.
//

import SwiftUI
import Charts

/// Numbers derived from the user's visits.
struct InsightsData {
    struct ShopScore: Identifiable {
        let id: String
        let name: String
        let average: Double
        let visits: Int
    }

    struct Order: Identifiable {
        var id: String { name }
        let name: String
        let count: Int
    }

    struct MonthCount: Identifiable {
        var id: Date { month }
        let month: Date
        let count: Int
    }

    let topShops: [ShopScore]
    let favoriteOrders: [Order]
    let monthly: [MonthCount]

    init(visits: [Visit], months: Int = 6, calendar: Calendar = .current, now: Date = Date()) {
        // Top shops by average rating, ignoring unrated visits.
        let byShop = Dictionary(grouping: visits.filter { $0.rating > 0 }, by: \.shopID)
        topShops = byShop
            .map { id, group in
                ShopScore(
                    id: id,
                    name: group[0].shopName,
                    average: Double(group.map(\.rating).reduce(0, +)) / Double(group.count),
                    visits: group.count
                )
            }
            .sorted { ($0.average, $0.visits) > ($1.average, $1.visits) }
            .prefix(3)
            .map { $0 }

        // Most frequent orders, compared case-insensitively.
        let orders = Dictionary(grouping: visits.filter { !$0.drink.isEmpty }) {
            $0.drink.trimmingCharacters(in: .whitespaces).lowercased()
        }
        favoriteOrders = orders
            .map { Order(name: $0.value[0].drink.trimmingCharacters(in: .whitespaces), count: $0.value.count) }
            .sorted { $0.count > $1.count }
            .prefix(3)
            .map { $0 }

        // Visits per month for the last several months, including empty ones.
        let currentMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        monthly = (0..<months).reversed().compactMap { offset in
            guard let month = calendar.date(byAdding: .month, value: -offset, to: currentMonth) else { return nil }
            let count = visits.filter { calendar.isDate($0.visitedAt, equalTo: month, toGranularity: .month) }.count
            return MonthCount(month: month, count: count)
        }
    }
}

struct InsightsView: View {
    let visits: [Visit]

    private var data: InsightsData { InsightsData(visits: visits) }

    var body: some View {
        let data = data

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !data.topShops.isEmpty {
                    section("Your top rated") {
                        VStack(spacing: 0) {
                            ForEach(Array(data.topShops.enumerated()), id: \.element.id) { index, shop in
                                HStack {
                                    Text("\(index + 1)")
                                        .font(.display(.title3, weight: .bold))
                                        .foregroundStyle(Theme.accent)
                                        .frame(width: 28)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(shop.name)
                                            .font(.display(.headline))
                                            .lineLimit(1)
                                        Text(shop.visits == 1 ? "1 visit" : "\(shop.visits) visits")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    StarsView(rating: Int(shop.average.rounded()), size: 12)
                                }
                                .padding(14)

                                if index < data.topShops.count - 1 {
                                    Divider().padding(.leading, 56)
                                }
                            }
                        }
                        .card()
                    }
                }

                if !data.favoriteOrders.isEmpty {
                    section("Your usual orders") {
                        VStack(spacing: 0) {
                            ForEach(Array(data.favoriteOrders.enumerated()), id: \.element.id) { index, order in
                                HStack {
                                    Text(order.name)
                                        .font(.subheadline.weight(.medium))
                                    Spacer()
                                    Text(order.count == 1 ? "1 time" : "\(order.count) times")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(14)

                                if index < data.favoriteOrders.count - 1 {
                                    Divider().padding(.leading, 14)
                                }
                            }
                        }
                        .card()
                    }
                }

                section("Visits by month") {
                    Chart(data.monthly) { item in
                        BarMark(
                            x: .value("Month", item.month, unit: .month),
                            y: .value("Visits", item.count)
                        )
                        .foregroundStyle(Theme.accent)
                        .cornerRadius(6)
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .month)) { _ in
                            AxisValueLabel(format: .dateTime.month(.abbreviated))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading, values: .automatic(desiredCount: 3))
                    }
                    .frame(height: 170)
                    .padding(16)
                    .card()
                }
            }
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.display(.title3))
            content()
        }
    }
}

/// Shown in place of Insights to free users.
struct ProUpsellCard: View {
    let systemImage: String
    let title: String
    let message: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 14) {
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
            Button("See Brewies Pro", action: action)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .padding(.horizontal, 24)
    }
}

//
//  StreakShareCard.swift
//  Brewies
//
//  The image a user shares when they post their streak.
//

import SwiftUI

/// A fixed-look card, independent of light or dark mode, rendered to an image for sharing.
struct StreakShareCard: View {
    let streak: Streak

    // Fixed colors so the shared image looks the same no matter the viewer's appearance.
    private let paper = Color(red: 0.965, green: 0.945, blue: 0.914)
    private let espresso = Color(red: 0.42, green: 0.27, blue: 0.16)
    private let ink = Color(red: 0.15, green: 0.10, blue: 0.07)

    static let size = CGSize(width: 360, height: 450)

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(espresso)
                    CategoryIcon(category: streak.shop.category, size: 18)
                        .foregroundStyle(.white)
                }
                .frame(width: 34, height: 34)
                Text("Brewies")
                    .font(.system(.title3, design: .serif, weight: .bold))
                    .foregroundStyle(ink)
                Spacer()
                Text(streak.tier.title.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(espresso)
            }

            Spacer()

            VStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(colors: [.yellow, .orange, .red], startPoint: .top, endPoint: .bottom)
                    )
                Text("\(streak.current)")
                    .font(.system(size: 124, weight: .bold, design: .serif))
                    .foregroundStyle(ink)
                    .minimumScaleFactor(0.5)
                Text(streak.current == 1 ? "week in a row" : "weeks in a row")
                    .font(.system(.title3, design: .serif, weight: .semibold))
                    .foregroundStyle(espresso)
            }

            Spacer()

            VStack(spacing: 14) {
                Text("at \(streak.shop.name)")
                    .font(.system(.title2, design: .serif, weight: .semibold))
                    .foregroundStyle(ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                HStack(spacing: 6) {
                    ForEach(Array(streak.recentWeeks.enumerated()), id: \.offset) { _, visited in
                        Circle()
                            .fill(visited ? espresso : espresso.opacity(0.14))
                            .frame(width: 16, height: 16)
                    }
                }

                Text("\(streak.totalVisits) \(streak.totalVisits == 1 ? "visit" : "visits") logged")
                    .font(.footnote)
                    .foregroundStyle(ink.opacity(0.6))
            }
        }
        .padding(28)
        .frame(width: Self.size.width, height: Self.size.height)
        .background(paper)
    }

    /// Renders the card to a high-resolution image.
    @MainActor
    static func image(for streak: Streak) -> UIImage? {
        let renderer = ImageRenderer(content: StreakShareCard(streak: streak))
        renderer.proposedSize = ProposedViewSize(size)
        renderer.scale = 3
        return renderer.uiImage
    }
}

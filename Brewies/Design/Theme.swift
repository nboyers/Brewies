//
//  Theme.swift
//  Brewies
//
//  Shared colors, type, and surface styles.
//

import SwiftUI

enum Theme {
    /// Warm espresso in light mode, latte in dark mode.
    static let accent = Color(
        light: Color(red: 0.42, green: 0.27, blue: 0.16),
        dark: Color(red: 0.82, green: 0.64, blue: 0.45)
    )

    /// Screen background: warm paper in light mode, roasted dark in dark mode.
    static let background = Color(
        light: Color(red: 0.965, green: 0.945, blue: 0.914),
        dark: Color(red: 0.09, green: 0.07, blue: 0.06)
    )

    /// Card surface that sits on `background`.
    static let surface = Color(
        light: .white,
        dark: Color(red: 0.14, green: 0.115, blue: 0.098)
    )

    static let cornerRadius: CGFloat = 20
}

extension Color {
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}

extension Font {
    /// Serif display type used for shop names and screen headings.
    static func display(_ style: Font.TextStyle, weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .serif, weight: weight)
    }
}

// MARK: - Surfaces

/// A raised card on the paper background.
private struct CardSurface: ViewModifier {
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
        content
            .background(Theme.surface, in: shape)
            .overlay(shape.strokeBorder(Color.primary.opacity(0.05)))
            .shadow(color: .black.opacity(0.05), radius: 12, y: 4)
    }
}

/// A translucent surface for controls floating above the map. Uses Liquid Glass where available.
private struct FloatingSurface<S: Shape>: ViewModifier {
    let shape: S

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content.glassEffect(.regular, in: shape)
        } else {
            content.background(.regularMaterial, in: shape)
        }
    }
}

extension View {
    func card() -> some View {
        modifier(CardSurface())
    }

    func floatingSurface<S: Shape>(in shape: S) -> some View {
        modifier(FloatingSurface(shape: shape))
    }

    func floatingCard() -> some View {
        floatingSurface(in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
    }

    /// Standard screen background.
    func paperBackground() -> some View {
        background(Theme.background.ignoresSafeArea())
    }
}

// MARK: - Controls

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Theme.accent, in: Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
    }
}

/// A selectable pill used for categories and filters.
struct Chip: View {
    let title: String
    var systemImage: String?
    var category: BrewCategory?
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 8) {
            if let category {
                CategoryIcon(category: category, size: 16)
            } else if let systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
            }
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(isSelected ? Color.white : Color.primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isSelected ? Theme.accent : Theme.surface, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.primary.opacity(isSelected ? 0 : 0.08)))
    }
}

/// A vertical icon-over-label tile used for quick actions.
struct QuickActionLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.title3)
            Text(title)
                .font(.caption.weight(.medium))
        }
        .foregroundStyle(Theme.accent)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .card()
    }
}

/// Serif section heading with an optional trailing control.
struct SectionHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        HStack {
            Text(title)
                .font(.display(.title2))
            Spacer()
            trailing()
        }
    }
}

extension SectionHeader where Trailing == EmptyView {
    init(_ title: String) {
        self.init(title: title, trailing: { EmptyView() })
    }
}

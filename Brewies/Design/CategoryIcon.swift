//
//  CategoryIcon.swift
//  Brewies
//
//  Category artwork. SF Symbols has no beer glass, so the mug is drawn here.
//

import SwiftUI

/// A beer mug with a foam head and a handle, drawn as a single fillable shape.
struct BeerMugShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        func frame(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
            CGRect(x: rect.minX + x * w, y: rect.minY + y * h, width: width * w, height: height * h)
        }

        // Mug body.
        path.addRoundedRect(in: frame(0.10, 0.30, 0.52, 0.64), cornerSize: CGSize(width: 0.07 * w, height: 0.07 * h))

        // Handle: a rounded loop on the right, stroked into a solid outline.
        let handle = Path(roundedRect: frame(0.56, 0.42, 0.28, 0.34), cornerRadius: 0.10 * w)
        path.addPath(handle.strokedPath(StrokeStyle(lineWidth: 0.09 * w)))

        // Foam head made of three bumps.
        path.addEllipse(in: frame(0.06, 0.12, 0.30, 0.28))
        path.addEllipse(in: frame(0.24, 0.04, 0.32, 0.32))
        path.addEllipse(in: frame(0.42, 0.12, 0.30, 0.28))
        return path
    }
}

/// The icon for a category, sized in points and tinted by the surrounding foreground style.
struct CategoryIcon: View {
    let category: BrewCategory
    var size: CGFloat = 20

    var body: some View {
        switch category {
        case .coffee:
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: size * 0.9))
                .frame(width: size, height: size)
        case .brewery:
            BeerMugShape()
                .frame(width: size, height: size)
        }
    }
}

/// A round map pin showing the category icon. The active pin grows and takes the accent color.
struct CategoryPin: View {
    let category: BrewCategory
    var isVisited = false
    var isActive = false
    var size: CGFloat = 36

    var body: some View {
        ZStack {
            Circle()
                .fill(isActive || isVisited ? Theme.accent : Color(red: 0.55, green: 0.38, blue: 0.24))
            CategoryIcon(category: category, size: size * 0.5)
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .overlay(Circle().strokeBorder(.white, lineWidth: isActive ? 3 : 2))
        .shadow(color: .black.opacity(isActive ? 0.35 : 0.25), radius: isActive ? 6 : 3, y: 2)
        .scaleEffect(isActive ? 1.45 : 1, anchor: .bottom)
        .opacity(isActive ? 1 : 0.9)
        .animation(.spring(duration: 0.3), value: isActive)
        .accessibilityHidden(true)
    }
}

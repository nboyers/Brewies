//
//  LogVisitView.swift
//  Brewies
//

import SwiftUI
import SwiftData
import PhotosUI

/// Form for logging a new visit, or editing an existing one.
struct LogVisitView: View {
    private let shop: Shop
    private let existing: Visit?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var visitedAt: Date
    @State private var rating: Int
    @State private var drink: String
    @State private var notes: String
    @State private var photoData: Data?
    @State private var pickerItem: PhotosPickerItem?

    init(shop: Shop) {
        self.shop = shop
        self.existing = nil
        _visitedAt = State(initialValue: Date())
        _rating = State(initialValue: 0)
        _drink = State(initialValue: "")
        _notes = State(initialValue: "")
        _photoData = State(initialValue: nil)
    }

    init(visit: Visit) {
        self.shop = Shop(visit: visit)
        self.existing = visit
        _visitedAt = State(initialValue: visit.visitedAt)
        _rating = State(initialValue: visit.rating)
        _drink = State(initialValue: visit.drink)
        _notes = State(initialValue: visit.notes)
        _photoData = State(initialValue: visit.photoData)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(shop.name)
                            .font(.display(.title3))
                        if let address = shop.address {
                            Text(address)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    DatePicker("Date", selection: $visitedAt, in: ...Date(), displayedComponents: [.date, .hourAndMinute])
                    HStack {
                        Text("Rating")
                        Spacer()
                        RatingPicker(rating: $rating)
                    }
                    TextField("What did you order?", text: $drink)
                }

                Section("Notes") {
                    TextField("Tasting notes, atmosphere, who you went with…", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section("Photo") {
                    photoSection
                }

                if let existing {
                    Section {
                        Button("Delete Visit", role: .destructive) {
                            modelContext.delete(existing)
                            dismiss()
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .paperBackground()
            .navigationTitle(existing == nil ? "Log a Visit" : "Edit Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                }
            }
            .onChange(of: pickerItem) {
                loadPhoto()
            }
        }
    }

    @ViewBuilder
    private var photoSection: some View {
        if let photoData, let image = UIImage(data: photoData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .accessibilityLabel("Visit photo")

            Button("Remove Photo", role: .destructive) {
                self.photoData = nil
                pickerItem = nil
            }
        }

        PhotosPicker(selection: $pickerItem, matching: .images) {
            Label(photoData == nil ? "Add Photo" : "Change Photo", systemImage: "photo")
        }
    }

    private func loadPhoto() {
        guard let pickerItem else { return }
        Task {
            guard let data = try? await pickerItem.loadTransferable(type: Data.self) else { return }
            photoData = ImageResizer.jpegData(from: data, maxDimension: 1600)
        }
    }

    private func save() {
        let trimmedDrink = drink.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if let existing {
            existing.visitedAt = visitedAt
            existing.rating = rating
            existing.drink = trimmedDrink
            existing.notes = trimmedNotes
            existing.photoData = photoData
        } else {
            modelContext.insert(Visit(shop: shop, visitedAt: visitedAt, rating: rating, drink: trimmedDrink, notes: trimmedNotes, photoData: photoData))
        }
        dismiss()
    }
}

enum ImageResizer {
    /// Downsizes and compresses a photo so it stays small in storage and sync.
    static func jpegData(from data: Data, maxDimension: CGFloat) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let longestSide = max(image.size.width, image.size.height)
        let scale = min(1, maxDimension / longestSide)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: size)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return resized.jpegData(compressionQuality: 0.8)
    }
}

//
//  JournalExport.swift
//  Brewies
//
//  Exports the user's journal as a CSV file they can share or save.
//

import SwiftUI
import UniformTypeIdentifiers

/// A snapshot of the journal that can be shared as a CSV file.
struct JournalExport: Transferable {
    struct Row: Sendable {
        let date: Date
        let shop: String
        let address: String
        let rating: Int
        let order: String
        let notes: String
        let latitude: Double
        let longitude: Double
    }

    let rows: [Row]

    init(visits: [Visit]) {
        rows = visits
            .sorted { $0.visitedAt > $1.visitedAt }
            .map {
                Row(
                    date: $0.visitedAt,
                    shop: $0.shopName,
                    address: $0.address,
                    rating: $0.rating,
                    order: $0.drink,
                    notes: $0.notes,
                    latitude: $0.latitude,
                    longitude: $0.longitude
                )
            }
    }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { export in
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let file = directory.appendingPathComponent("Brewies Journal.csv")
            try export.csv.write(to: file, atomically: true, encoding: .utf8)
            return SentTransferredFile(file)
        }
    }

    var csv: String {
        let header = "Date,Shop,Address,Rating,Order,Notes,Latitude,Longitude"
        let formatter = ISO8601DateFormatter()
        let lines = rows.map { row in
            [
                formatter.string(from: row.date),
                row.shop,
                row.address,
                row.rating == 0 ? "" : String(row.rating),
                row.order,
                row.notes,
                String(row.latitude),
                String(row.longitude)
            ]
            .map(Self.escape)
            .joined(separator: ",")
        }
        return ([header] + lines).joined(separator: "\n") + "\n"
    }

    /// Quotes a field when it contains a comma, quote or newline.
    private static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" }) else { return field }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

//
//  IndependentShopFilter.swift
//  Brewies
//
//  Recognizes well-known chains so searches can show independent shops only.
//

import Foundation

enum IndependentShopFilter {
    /// Chain names, matched as whole-word sequences so "Noble Coffee" is not caught by "barnes noble".
    private static let chainNames: [[String]] = [
        // Coffee and bakery-cafe
        "starbucks", "dunkin", "peets", "tim hortons", "caribou coffee", "dutch bros", "scooters coffee",
        "biggby", "coffee bean", "costa coffee", "mccafe", "panera", "einstein bros", "krispy kreme",
        "tullys", "black rifle", "7 brew", "human bean", "philz", "blue bottle", "la colombe",
        "gloria jeans", "second cup", "juan valdez", "pret a manger", "au bon pain", "corner bakery",
        "la madeleine", "crumbl", "nothing bundt cakes", "tropical smoothie",
        // Fast food, convenience, and retail that carry cafe types
        "mcdonalds", "burger king", "wendys", "subway", "walmart", "target", "barnes noble",
        "books a million", "whole foods", "trader joes", "kroger", "safeway", "wawa", "sheetz",
        "7 eleven", "circle k", "cumberland farms", "speedway",
        // Bar and restaurant chains
        "applebees", "buffalo wild wings", "hooters", "chilis", "tgi fridays", "olive garden",
        "red robin", "texas roadhouse", "outback steakhouse", "ruby tuesday", "dave busters", "topgolf",
        "yard house", "bjs restaurant", "total wine", "bevmo", "world of beer", "old chicago",
        "twin peaks", "millers ale house", "wild wings"
    ].map(tokens(in:))

    static func isChain(_ name: String) -> Bool {
        let nameTokens = tokens(in: name)
        return chainNames.contains { chain in
            guard !chain.isEmpty, chain.count <= nameTokens.count else { return false }
            return (0...(nameTokens.count - chain.count)).contains { start in
                Array(nameTokens[start..<(start + chain.count)]) == chain
            }
        }
    }

    /// Lowercased words with diacritics and punctuation removed ("Peet's Coffee" -> ["peets", "coffee"]).
    private static func tokens(in text: String) -> [String] {
        let folded = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let cleaned = folded.unicodeScalars.compactMap { scalar -> Character? in
            if scalar == "'" || scalar == "\u{2019}" { return nil }
            return CharacterSet.alphanumerics.contains(scalar) ? Character(scalar) : " "
        }
        return String(cleaned).split(separator: " ").map(String.init)
    }
}

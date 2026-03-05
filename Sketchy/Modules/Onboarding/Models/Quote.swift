//
//  Quote.swift
//  Sketchy
//
//  Created by Claude
//

import Foundation

// MARK: - Quote Response

struct QuoteResponse: Codable {
    let quotes: [Quote]
}

// MARK: - Quote Model

struct Quote: Codable {
    let quote: String
    let author: String
}

// MARK: - Quote Manager

/// Manages loading and providing random quotes
@MainActor
class QuoteManager {

    // MARK: - Singleton

    static let shared = QuoteManager()

    private init() {}

    // MARK: - Properties

    private var quotes: [Quote] = []

    // MARK: - Public Methods

    /// Load quotes from JSON file
    func loadQuotes() {
        guard let url = Bundle.main.url(forResource: "quotes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let quoteResponse = try? JSONDecoder().decode(QuoteResponse.self, from: data) else {
            print("Failed to load quotes from JSON")
            return
        }

        quotes = quoteResponse.quotes
    }

    /// Get a random quote
    func getRandomQuote() -> Quote {
        if quotes.isEmpty {
            loadQuotes()
        }

        return quotes.randomElement() ?? Quote(
            quote: "Drawing is putting a line around an idea.",
            author: "Henri Matisse"
        )
    }
}

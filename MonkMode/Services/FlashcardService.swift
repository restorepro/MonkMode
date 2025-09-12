//
//  FlashcardService.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

import Foundation

@MainActor
final class FlashcardService: ObservableObject {
    static let shared = FlashcardService()
    @Published private(set) var cards: [Flashcard] = []

    private let fileName = "Flashcards.json"

    private init() { load() }

    func addCard(_ card: Flashcard) {
        cards.append(card)
        save()
    }

    private func save() {
        FileService.shared.save(cards, to: fileName)
    }

    private func load() {
        cards = FileService.shared.load([Flashcard].self, from: fileName) ?? []
    }
}

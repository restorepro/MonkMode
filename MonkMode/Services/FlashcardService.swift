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
    func importBulkJSON(_ json: String, course: String, chapter: String) {
        guard let data = json.data(using: .utf8) else { return }
        do {
            struct PartialCard: Codable {
                let question: String
                let answer: String
                let imageUrl: String?
                let additionalInfo: String?
            }
            let partials = try JSONDecoder().decode([PartialCard].self, from: data)

            var newCards: [Flashcard] = []
            for p in partials {
                let card = Flashcard(
                    id: UUID(),
                    question: p.question,
                    answer: p.answer,
                    course: course,
                    chapter: chapter,
                    easeFactor: 250,
                    intervalDays: 1,
                    repetitions: 0,
                    nextReview: nil,
                    imageUrl: p.imageUrl,
                    additionalInfo: p.additionalInfo,
                    bookmarkedSentences: [],
                    variants: nil,
                    flowMeta: nil,
                    variantType: nil,
                    choices: nil
                )
                cards.append(card)
                newCards.append(card)
            }
            save()
            print("🟢 Imported \(newCards.count) cards into course=\(course), chapter=\(chapter)")
        } catch {
            print("❌ Bulk import failed: \(error)")
        }
    }

}

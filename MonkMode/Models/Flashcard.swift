//
//  Flashcard.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

import Foundation

struct Flashcard: Identifiable, Codable, Equatable {
    var id: UUID
    var question: String
    var answer: String
    var course: String?
    var chapter: String?

    // Spaced repetition fields
    var easeFactor: Int?
    var intervalDays: Int?
    var repetitions: Int?
    var nextReview: TimeInterval?

    // Engagement fields
    var imageUrl: String?
    var additionalInfo: String?
    var bookmarkedSentences: [String]?

    // 🆕 new: variants
    var variants: [FlashcardVariant]?

    // 🆕 for subtle labels
    var flowMeta: FlowMeta? = nil

    // 🆕 track what kind of card this is after expansion
    var variantType: VariantType? = nil
        
    // 🆕 multiple choice support
    var choices: [String]? = nil
}

struct FlashcardVariant: Codable, Equatable {
    var type: VariantType
    var prompt: String
    var answer: String
    var choices: [String]?   // ✅ optional, only used for multipleChoice
}

enum VariantType: String, Codable {
    case reverse
    case multipleChoice
    case fillInBlank
    case associative
}

enum FlowMeta: Codable, Equatable {
    case vertical
    case lateral(current: Int, total: Int)
}

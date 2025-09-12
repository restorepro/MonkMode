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

    // Card type
    var type: FlashcardType = .standard

    // Optional fields
    var choices: [String]?      // Multiple choice options
    var correctIndex: Int?      // Index of correct choice
    var isFillInTheBlank: Bool? // Mark if it’s fill-in style

    var course: String?
    var chapter: String?
    var easeFactor: Int?        // Spaced repetition
    var intervalDays: Int?
    var repetitions: Int?
    var nextReview: TimeInterval?
    var imageUrl: String?
    var additionalInfo: String?

    var bookmarkedSentences: [String]? = []
}

enum FlashcardType: String, Codable {
    case standard
    case multipleChoice
    case fillInBlank
    case trueFalse
}

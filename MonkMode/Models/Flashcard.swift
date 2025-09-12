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

    // ✅ Make type optional, default = .standard
    var type: FlashcardType? = .standard

    var choices: [String]? = nil
    var correctIndex: Int? = nil

    var course: String?
    var chapter: String?
    var easeFactor: Int?
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

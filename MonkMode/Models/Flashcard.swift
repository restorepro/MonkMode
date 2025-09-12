//
//  Flashcard.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

import Foundation

struct Flashcard: Identifiable, Codable {
    var id: UUID
    var question: String
    var answer: String
    var type: FlashcardType = .standard
    var choices: [String]? = nil
    var correctIndex: Int? = nil

    var course: String
    var chapter: String
}

enum FlashcardType: String, Codable {
    case standard, multipleChoice, fillInBlank, trueFalse
}

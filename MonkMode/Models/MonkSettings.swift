//
//  MonkSettings.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

import Foundation

struct MonkSettings: Codable {
    var questionDuration: Int = 5   // seconds per question
    var answerDuration: Int = 5     // seconds per answer
    var shuffle: Bool = false       // shuffle flashcards
}

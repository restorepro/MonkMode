//
//  StudySession.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

import Foundation

struct StudySession: Identifiable, Codable {
    var id = UUID()
    var mode: StudyMode
    var course: String
    var chapter: String
    var duration: TimeInterval   // in seconds
    var score: Int?
    var date: Date
}

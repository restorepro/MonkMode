//
//  StudySession.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

import Foundation

struct StudySession: Identifiable, Codable {
    let id: UUID
    let date: Date
    let mode: String
    let course: String?
    let chapter: String?
    let duration: TimeInterval
    let score: Int?
    let missed: Int?
}

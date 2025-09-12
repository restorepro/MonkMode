//
//  ReaderChapter.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

import Foundation

struct ReaderChapter: Identifiable, Codable {
    var id: UUID
    var course: String
    var chapter: String
    var paragraphs: [String]
}

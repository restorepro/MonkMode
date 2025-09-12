//
//  ReaderService.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

import Foundation

@MainActor
final class ReaderService: ObservableObject {
    static let shared = ReaderService()
    @Published private(set) var chapters: [ReaderChapter] = []

    private let fileName = "Reader.json"

    private init() {
        load()
    }

    func addChapter(course: String, chapter: String, paragraphs: [String]) {
        let new = ReaderChapter(id: UUID(), course: course, chapter: chapter, paragraphs: paragraphs)
        chapters.append(new)
        save()
    }

    func getChapter(course: String, chapter: String) -> ReaderChapter? {
        chapters.first { $0.course == course && $0.chapter == chapter }
    }

    private func save() {
        FileService.shared.save(chapters, to: fileName)
    }

    private func load() {
        chapters = FileService.shared.load([ReaderChapter].self, from: fileName) ?? []
    }
}

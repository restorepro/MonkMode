//
//  MonkViewModel.swift
//  MonkMode
//
//  Created by Greg Williams on 11.09.2025.
//

import Foundation
import Combine

@MainActor
final class MonkViewModel: ObservableObject {
    // MARK: - Published state for Views
    @Published var cards: [Flashcard] = []
        @Published var chapters: [ReaderChapter] = []
        @Published var sessions: [StudySession] = []
        @Published var currentIndex: Int = 0
        @Published var selectedCourse: String? = nil
        @Published var selectedChapter: String? = nil //MonkView compiles
    
    // MARK: - Services (use .shared singletons)
    private let flashcardService = FlashcardService.shared
    private let readerService = ReaderService.shared
    private let sessionService = SessionService.shared
    private let fileService = FileService.shared
    @Published var settings = MonkSettings()

    
    // MARK: - Init
    init() {
        loadSeedData()
        loadSessions()
    }
    
    // MARK: - Data Loading
    private func loadSeedData() {
        // You might want separate seed files later, for now use one
        if let seededFlashcards: [Flashcard] = fileService.load([Flashcard].self, from: "MonkSeed.json") {
            self.cards = seededFlashcards
        }
        if let seededChapters: [ReaderChapter] = fileService.load([ReaderChapter].self, from: "MonkSeed.json") {
            self.chapters = seededChapters
        }
    }
    
    private func loadSessions() {
        self.sessions = sessionService.load()
    }
    
    // MARK: - User Actions
    func addFlashcard(_ card: Flashcard) {
        cards.append(card)
        flashcardService.addCard(card)   // ✅ match your FlashcardService API
    }
    
    func addSession(_ session: StudySession) {
        sessions.append(session)
        sessionService.addSession(session)   // ✅ you’ll need to define this in SessionService
    }
    
    func getChapters(for course: String) -> [ReaderChapter] {
        chapters.filter { $0.course == course }
    }
}

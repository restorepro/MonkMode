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
    @Published var cards: [Flashcard] = []
    @Published var currentIndex: Int = 0
    @Published var timeRemaining: Int = 5
    @Published var showingAnswer: Bool = false
    @Published var isFinished: Bool = false
    @Published var score: Int = 0
    @Published var missed: [Flashcard] = []
    @Published var settings = MonkSettings()

    private var timer: AnyCancellable?
    private(set) var startTime = Date()
    

    let course: String
    let chapter: String

    init(cards: [Flashcard]? = nil, course: String = "Psych 101", chapter: String = "Monk Demo") {
        if let provided = cards, !provided.isEmpty {
            self.cards = provided
        } else {
            self.cards = MonkViewModel.loadSeedCards()
        }
        self.course = course
        self.chapter = chapter
        startTimer()
    }

    func startTimer() {
        timeRemaining = settings.questionDuration
        showingAnswer = false
        timer?.cancel()

        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        guard currentIndex < cards.count else { return }

        if timeRemaining > 0 {
            timeRemaining -= 1
        } else if !showingAnswer {
            showingAnswer = true
            timeRemaining = settings.answerDuration   // ✅ now uses setting
        } else {
            nextCard()
        }
    }


    private func nextCard() {
        currentIndex += 1
        if currentIndex >= cards.count {
            finishSession()
        } else {
            startTimer()
        }
    }

    func markCorrect() {
        score += 1
    }

    func markIncorrect() {
        missed.append(cards[currentIndex])
    }

    private func finishSession() {
        timer?.cancel()
        isFinished = true

        let session = StudySession(
            id: UUID(),
            date: Date(),
            mode: "Monk",
            course: course,
            chapter: chapter,
            duration: Date().timeIntervalSince(startTime),
            score: score,
            missed: missed.count
        )
        SessionService.shared.addSession(session)   // ✅ integrate with your new service
    }

    static func loadSeedCards() -> [Flashcard] {
        guard let url = Bundle.main.url(forResource: "flashcards", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("❌ Could not find flashcards.json in bundle")
            return []
        }
        do {
            let cards = try JSONDecoder().decode([Flashcard].self, from: data)
            print("📚 Loaded \(cards.count) flashcards")
            return cards
        } catch {
            print("❌ Failed to decode flashcards.json: \(error)")
            return []
        }
    }

}

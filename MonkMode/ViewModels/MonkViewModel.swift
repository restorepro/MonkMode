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
    
    @Published var useTestData: Bool = false
    @Published var useLateralClustering: Bool = false   // 🆕 new toggle

    let course: String
    let chapter: String

    init(
        cards: [Flashcard]? = nil,
        course: String = "Psych 101",
        chapter: String = "Monk Demo",
        useTestData: Bool = true,
        useLateralClustering: Bool = false
    ) {
        self.useTestData = useTestData
        self.useLateralClustering = useLateralClustering
        self.course = course
        self.chapter = chapter

        if let provided = cards, !provided.isEmpty {
            self.cards = provided
        } else {
            self.cards = MonkViewModel.loadSeedCards(
                useTestData: useTestData,
                useLateralClustering: useLateralClustering
            )
        }

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

    // MonkViewModel.swift
    static func loadSeedCards(
        useTestData: Bool = false,
        useLateralClustering: Bool = false
    ) -> [Flashcard] {
        let fileName = useTestData ? "MonkSeed" : "flashcards"

        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            print("❌ \(fileName).json not found in bundle")
            return []
        }

        do {
            let baseCards = try JSONDecoder().decode([Flashcard].self, from: data)
            print("📚 Loaded \(baseCards.count) flashcards from \(fileName).json")

            // 🔄 Expand deck according to toggle
            let expanded = expandCards(baseCards, useLateralClustering: useLateralClustering)
            print("📚 Expanded to \(expanded.count) cards (clustering: \(useLateralClustering))")

            return expanded
        } catch {
            print("❌ Failed to decode \(fileName).json: \(error)")
            return []
        }
    }
    private static func expandCards(
        _ cards: [Flashcard],
        useLateralClustering: Bool
    ) -> [Flashcard] {
        var expanded: [Flashcard] = []

        for card in cards {
            var baseCard = card
            baseCard.flowMeta = .vertical
            expanded.append(baseCard)

            if let variants = card.variants {
                let total = variants.count
                for (index, v) in variants.enumerated() {
                    var variantCard = makeVariantCard(from: card, variant: v)
                    variantCard.flowMeta = .lateral(current: index + 1, total: total)
                    expanded.append(variantCard)
                }
            }
        }
        return expanded
    }


    private static func makeVariantCard(from card: Flashcard, variant: FlashcardVariant) -> Flashcard {
        Flashcard(
            id: UUID(),
            question: variant.prompt,
            answer: variant.answer,
            course: card.course,
            chapter: card.chapter
        )
    }


}

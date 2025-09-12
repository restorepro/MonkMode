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
    @Published var sessionLogs: [StudySession] = []

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
        print("🚀 MonkViewModel init (course=\(course), chapter=\(chapter))")
        self.useTestData = useTestData
        self.useLateralClustering = useLateralClustering
        self.course = course
        self.chapter = chapter

        if let provided = cards, !provided.isEmpty {
            self.cards = provided
            print("📥 MonkViewModel: Using provided \(provided.count) cards")
        } else {
            self.cards = MonkViewModel.loadSeedCards(
                useTestData: useTestData,
                useLateralClustering: useLateralClustering
            )
        }

        print("📊 MonkViewModel initialized with \(self.cards.count) cards")
        startTimer()
    }

    func startTimer() {
        timeRemaining = settings.questionDuration
        showingAnswer = false
        timer?.cancel()
        print("⏱️ Timer started (questionDuration=\(settings.questionDuration)) for card index=\(currentIndex)")

        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        guard currentIndex < cards.count else { return }

        if timeRemaining > 0 {
            timeRemaining -= 1
            print("⏳ Tick: \(timeRemaining)s left (showingAnswer=\(showingAnswer))")
        } else if !showingAnswer {
            showingAnswer = true
            timeRemaining = settings.answerDuration
            print("👁️ Revealing answer for card index \(currentIndex) – new timer=\(timeRemaining)s")
        } else {
            print("➡️ Tick finished answer duration, advancing to next card")
            nextCard()
        }
    }

    func nextCard() {
        currentIndex += 1
        print("🔜 nextCard(): advanced to index \(currentIndex)")

        if currentIndex >= cards.count {
            print("🏁 All cards completed, finishing session")
            finishSession()
        } else {
            startTimer()
        }
    }

    func markCorrect() {
        print("👍 markCorrect(): index=\(currentIndex)")
        score += 1
        nextCard()
    }

    func markIncorrect() {
        print("👎 markIncorrect(): index=\(currentIndex)")
        if currentIndex < cards.count {
            missed.append(cards[currentIndex])
        }
        nextCard()
    }

    private func finishSession() {
        timer?.cancel()
        isFinished = true
        print("✅ finishSession(): score=\(score), missed=\(missed.count), duration=\(Date().timeIntervalSince(startTime))s")

        let session = StudySession(
            id: UUID(),
            mode: .treadmill,   // or .free / .reading / .quiz depending on where this runs
            course: course,
            chapter: chapter,
            duration: Date().timeIntervalSince(startTime),
            score: score,
            date: Date()
        )
        sessionLogs.append(session)
        print("📝 Session logged (total logs=\(sessionLogs.count))")
    }

    // MARK: - Loading seed cards
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
        print("🔄 expandCards(): starting with \(cards.count) base cards")

        for card in cards {
            var baseCard = card
            baseCard.flowMeta = .vertical
            expanded.append(baseCard)
            print("➕ Added base card: \(card.question)")

            if let variants = card.variants {
                let total = variants.count
                for (index, v) in variants.enumerated() {
                    var variantCard = makeVariantCard(from: card, variant: v)
                    variantCard.flowMeta = .lateral(current: index + 1, total: total)
                    print("   🔗 Variant card created → type=\(v.type), flowMeta=lateral(\(index+1)/\(total))")

                    expanded.append(variantCard)
                    print("   ➕ Added variant [\(v.type)] (\(index+1)/\(total)) for card: \(card.question)")
                }
            }
        }

        print("🔄 expandCards(): finished, total expanded=\(expanded.count)")
        return expanded
    }

    private static func makeVariantCard(from card: Flashcard, variant: FlashcardVariant) -> Flashcard {
        var f = Flashcard(
            id: UUID(),
            question: variant.prompt,
            answer: variant.answer,
            course: card.course,
            chapter: card.chapter
        )
        f.variantType = variant.type   // ✅ capture the type here
        f.choices = variant.choices

        return f
    }

}

// MARK: - Session analytics
extension MonkViewModel {
    var sessionsTodayMinutes: Int {
        let cal = Calendar.current
        let total = sessionLogs
            .filter { cal.isDateInToday($0.date) }
            .map { Int($0.duration / 60) }
            .reduce(0, +)
        print("📈 sessionsTodayMinutes = \(total)")
        return total
    }

    var sessionsWeekMinutes: Int {
        let cal = Calendar.current
        guard let weekAgo = cal.date(byAdding: .day, value: -6, to: Date()) else { return 0 }
        let total = sessionLogs
            .filter { $0.date >= cal.startOfDay(for: weekAgo) }
            .map { Int($0.duration / 60) }
            .reduce(0, +)
        print("📈 sessionsWeekMinutes = \(total)")
        return total
    }

    var sessionStreak: Int {
        let cal = Calendar.current
        let days = Set(sessionLogs.map { cal.startOfDay(for: $0.date) }).sorted(by: >)
        guard !days.isEmpty else { return 0 }

        var streak = 1
        var prev = days[0]

        for day in days.dropFirst() {
            if let diff = cal.dateComponents([.day], from: day, to: prev).day, diff == 1 {
                streak += 1
                prev = day
            } else {
                break
            }
        }
        print("🔥 sessionStreak = \(streak)")
        return streak
    }
}
#if DEBUG
extension MonkViewModel {
    func debugNextCard() {
        print("🐞 debugNextCard() called at index \(currentIndex)")
        nextCard()
    }

    func debugToggleAnswer() {
        showingAnswer.toggle()
        print("🐞 debugToggleAnswer() toggled to \(showingAnswer) at index \(currentIndex)")
    }
}
#endif

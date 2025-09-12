//
//  SessionManagerVM.swift
//  MonkMode
//
//  Created by Greg Williams on 12.09.2025.
//

import Foundation
import AVFoundation

@MainActor
final class SessionManagerVM: ObservableObject {
    // MARK: - Published UI State
    @Published var mode: StudyMode
    @Published var cards: [Flashcard]
    @Published var currentIndex: Int = 0
    @Published var isRunning: Bool = false
    @Published var score: Int = 0
    @Published var startTime: Date = Date()
    @Published var course: String
    @Published var chapter: String
    @Published var isFinished: Bool = false
    @Published var showingAnswer: Bool = false
    @Published var missed: [Flashcard] = []

    // MARK: - Hooks to reuse your existing app pieces
    var onLog: ((StudyMode, [Flashcard], TimeInterval, Int?) -> Void)?  // inject your existing logger

    // MARK: - Minimal speech (safe to remove when you plug your SpeechReader)
    private let synthesizer = AVSpeechSynthesizer()

    // MARK: - Init
    init(
        mode: StudyMode,
        cards: [Flashcard],
        course: String = "",
        chapter: String = "",
        onLog: ((StudyMode, [Flashcard], TimeInterval, Int?) -> Void)? = nil
    ) {
        self.mode = mode
        self.cards = cards
        self.course = course
        self.chapter = chapter
        self.onLog = onLog

        print("🚀 SessionManagerVM init → mode=\(mode), cards=\(cards.count), course=\(course), chapter=\(chapter)")
    }

    // MARK: - Controls
    func start() {
        isRunning = true
        startTime = Date()
        print("▶️ Session started at \(startTime)")
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        let duration = Date().timeIntervalSince(startTime)
        print("⏹️ Session stopped. Duration=\(duration)s, Score=\(score)")
        onLog?(mode, cards, duration, score)
    }

    func nextCard() {
        guard currentIndex < cards.count - 1 else {
            isFinished = true
            stop()
            print("🏁 Session finished after \(cards.count) cards. Final score=\(score)")
            return
        }
        currentIndex += 1
        showingAnswer = false   // 🔑 reset for the new card
        print("➡️ Advanced to card index=\(currentIndex)/\(cards.count)")
    }

    // MARK: - TTS helpers
    func readCurrentCard() {
        guard currentIndex < cards.count else { return }
        let c = cards[currentIndex]
        let text = c.question + " " + c.answer
        let u = AVSpeechUtterance(string: text)
        synthesizer.speak(u)
        print("🔊 Reading card: \(c.question) → \(c.answer)")
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        print("🔇 Stopped speech synthesis")
    }

    // MARK: - Answer tracking
    func markCorrect() {
        score += 1
        print("✅ Marked correct at index \(currentIndex). Score=\(score)")
    }

    func markIncorrect() {
        if currentIndex < cards.count {
            missed.append(cards[currentIndex])
            print("❌ Marked incorrect at index \(currentIndex). Missed count=\(missed.count)")
        }
    }
}

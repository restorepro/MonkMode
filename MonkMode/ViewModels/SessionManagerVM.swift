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

    // MARK: - Hooks to reuse your existing app pieces
    var onLog: ((StudyMode, [Flashcard], TimeInterval, Int?) -> Void)?  // inject your existing logger

    // MARK: - Minimal speech (safe to remove when you plug your SpeechReader)
    private let synthesizer = AVSpeechSynthesizer()

    // MARK: - Init
    init(mode: StudyMode,
         cards: [Flashcard],
         onLog: ((StudyMode, [Flashcard], TimeInterval, Int?) -> Void)? = nil)
    {
        self.mode = mode
        self.cards = cards
        self.onLog = onLog
    }

    // MARK: - Controls
    func start() {
        isRunning = true
        startTime = Date()
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        onLog?(mode, cards, Date().timeIntervalSince(startTime), score)
    }

    func nextCard() {
        guard currentIndex < cards.count - 1 else {
            stop()
            return
        }
        currentIndex += 1
    }

    func readCurrentCard() {
        guard currentIndex < cards.count else { return }
        let c = cards[currentIndex]
        let text = c.question + " " + c.answer
        let u = AVSpeechUtterance(string: text)
        synthesizer.speak(u)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}

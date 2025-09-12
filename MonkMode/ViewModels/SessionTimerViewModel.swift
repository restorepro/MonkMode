//
//  SessionTimerViewModel.swift
//  Flashcards
//
//  Created by Greg Williams on 03.09.2025.
//

import Foundation

final class SessionTimerViewModel: ObservableObject {
    @Published var isRunning = false
    @Published var elapsed: TimeInterval = 0

    private var timer: Timer?
    private var startDate: Date?

    func start() {
        guard !isRunning else { return }
        isRunning = true
        startDate = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self, let start = self.startDate else { return }
            self.elapsed = Date().timeIntervalSince(start)
        }
    }

    func pause() {
        guard isRunning else { return }
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func reset() {
        pause()
        elapsed = 0
        startDate = nil
    }
}
